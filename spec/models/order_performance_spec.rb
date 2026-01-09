require 'rails_helper'
require 'benchmark'

RSpec.describe Order, type: :model do
  describe 'Performance Tests' do
    before(:all) do
      # Criar dados de teste uma vez para todos os testes de performance
      DatabaseCleaner.clean_with(:truncation)

      @products = create_list(:product, 50)
      @orders = []

      total = 5_000
      puts "Criando #{total} pedidos..."

      total.times do |i|
        @orders << create(:order, product: @products.sample)

        if (i + 1) % 1000 == 0
          percentage = ((i + 1).to_f / total * 100).round(1)
          bar_length = 50
          filled = (percentage / 100 * bar_length).round
          empty = [bar_length - filled - 1, 0].max
          bar = '=' * filled + '>' + ' ' * empty
          print "\r[#{bar}] #{percentage}% (#{i + 1}/#{total})"
        end
      end

      puts "\n"

      puts "\n" + "=" * 60
      puts "DADOS DE TESTE CRIADOS:"
      puts "  - #{Product.count} produtos"
      puts "  - #{Order.count} pedidos"
      puts "=" * 60 + "\n"
    end

    after(:all) do
      DatabaseCleaner.clean_with(:truncation)
    end

    describe '.generate_report' do
      it 'mede o tempo de execução do relatório' do
        # Este teste deve mostrar o problema N+1
        # ANTES da otimização: muitas queries (1 + N)
        # DEPOIS da otimização: poucas queries (eager loading)

        puts "\n--- Teste: generate_report ---"

        query_count = 0
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          # Ignorar queries de schema e BEGIN/COMMIT
          unless ['SCHEMA', 'CACHE'].include?(payload[:name]) || payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT)/
            query_count += 1
          end
        end

        time = Benchmark.measure do
          Order.generate_report
        end

        ActiveSupport::Notifications.unsubscribe(subscriber)

        puts "Tempo de execução: #{time.real.round(4)} segundos"
        puts "Número de queries: #{query_count}"
        puts "-" * 40

        expect(Order.generate_report).to be_an(Array)
      end
    end

    describe '.orders_summary_by_status' do
      it 'mede o tempo de execução do sumário por status' do
        puts "\n--- Teste: orders_summary_by_status ---"

        query_count = 0
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          unless ['SCHEMA', 'CACHE'].include?(payload[:name]) || payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT)/
            query_count += 1
          end
        end

        time = Benchmark.measure do
          Order.orders_summary_by_status
        end

        ActiveSupport::Notifications.unsubscribe(subscriber)

        puts "Tempo de execução: #{time.real.round(4)} segundos"
        puts "Número de queries: #{query_count}"
        puts "-" * 40

        # META: Após otimização, deve usar apenas 1 query com GROUP BY
        expect(Order.orders_summary_by_status).to be_a(Hash)
      end
    end

    describe '.search_by_customer' do
      it 'mede o tempo de busca por email do cliente' do
        puts "\n--- Teste: search_by_customer ---"

        time = Benchmark.measure do
          500.times do
            Order.search_by_customer('customer')
          end
        end

        puts "Tempo para 5000 buscas: #{time.real.round(4)} segundos"
        puts "Média por busca: #{(time.real / 5000 * 1000).round(4)} ms"
        puts "-" * 40

        # META: Após adicionar índice, deve ser significativamente mais rápido
        expect(Order.search_by_customer('customer')).to respond_to(:each)
      end
    end

    describe '.find_by_date_range' do
      it 'mede o tempo de busca por intervalo de datas' do
        puts "\n--- Teste: find_by_date_range ---"

        start_date = 6.months.ago.to_date
        end_date = Date.today

        time = Benchmark.measure do
          500.times do
            Order.find_by_date_range(start_date, end_date)
          end
        end

        puts "Tempo para 5000 buscas: #{time.real.round(4)} segundos"
        puts "Média por busca: #{(time.real / 500 * 1000).round(4)} ms"
        puts "-" * 40

        # META: Após adicionar índice em order_date, deve ser mais rápido
        expect(Order.find_by_date_range(start_date, end_date)).to respond_to(:each)
      end
    end

    describe '.count_orders_by_city' do
      it 'mede o tempo de contagem por cidade' do
        puts "\n--- Teste: count_orders_by_city ---"

        query_count = 0
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          unless ['SCHEMA', 'CACHE'].include?(payload[:name]) || payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT)/
            query_count += 1
          end
        end

        time = Benchmark.measure do
          Order.count_orders_by_city
        end

        ActiveSupport::Notifications.unsubscribe(subscriber)

        puts "Tempo de execução: #{time.real.round(4)} segundos"
        puts "Número de queries: #{query_count}"
        puts "-" * 40

        # META: Após otimização com GROUP BY, deve usar apenas 1 query
        expect(Order.count_orders_by_city).to be_a(Hash)
      end
    end

    describe '.calculate_daily_revenue' do
      it 'mede o tempo de cálculo de receita diária' do
        puts "\n--- Teste: calculate_daily_revenue ---"

        date = Date.today - 30.days

        time = Benchmark.measure do
          500.times do
            Order.calculate_daily_revenue(date)
          end
        end

        puts "Tempo para 500 cálculos: #{time.real.round(4)} segundos"
        puts "Média por cálculo: #{(time.real / 500 * 1000).round(4)} ms"
        puts "-" * 40

        # META: Após usar SUM no banco, deve ser muito mais rápido
        expect(Order.calculate_daily_revenue(date)).to be_a(Numeric)
      end
    end
  end

  describe 'Query Count Tests (N+1 Detection)' do
    before do
      @products = create_list(:product, 10)
      10000.times { create(:order, product: @products.sample) }
    end

    it 'detecta problema N+1 no generate_report' do
      query_count = 0

      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
        unless ['SCHEMA', 'CACHE'].include?(payload[:name]) || payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT)/
          query_count += 1
        end
      end

      Order.generate_report

      ActiveSupport::Notifications.unsubscribe(subscriber)

      puts "\n[N+1 Test] generate_report executou #{query_count} queries"
      puts "-" * 40

      # ANTES da otimização: > 1000 queries (1 + N para cada order)
      # DEPOIS da otimização: deve ser < 3 queries
      # Este expect vai FALHAR antes da otimização - é intencional!
      expect(query_count).to be < 3
    end
  end

  describe "PROBLEMA: Múltiplas queries desnecessárias" do
    before do
      @products = create_list(:product, 10)
      10000.times { create(:order, product: @products.sample) }
    end

    it "detecta query desnecessarias" do
      query_count = 0

      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
        unless ['SCHEMA', 'CACHE'].include?(payload[:name]) || payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT)/
          query_count += 1
        end
      end

      ActiveSupport::Notifications.unsubscribe(subscriber)

      puts "\n[query desnecessarias Test] generate_report executou #{query_count} queries"
      puts "-" * 40

      expect(query_count).to be 0
    end
  end

  describe "Teste calculo da media" do
    context "com divisor zero" do
      it "retorna zero" do
        expect(Order.calculate_average(9, 0)).to be 0
      end
    end

    context "com divisor zero" do
      it "retorna a media" do
        expect(Order.calculate_average(9, 3)).to be 3
      end
    end
  end
end
