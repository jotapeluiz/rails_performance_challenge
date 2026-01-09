# Solução

## Order.generate_report

O problema encontrado foi que a busca é feita apenas na tabela Orders
porém a cada iteração da collection de Orders é preciso exibir os dados do produto associado.
A solução nesse caso foi adicionar a tabela Products usando o includes desse modo é feita uma
única consulta trazendo os dados necessários

## Order.orders_summary_by_status

Problema neste caso é fazer uma consulta a cada status passado, o que torna oneroso a carga no banco
portanto optei por agrupar tudo pelo status e filtrar em memória os dados realizando os devidos cálculos

## Order.search_by_customer

Problema é a pesquisa ampla em uma tabela que cresce a todo momento e como o usuário
terá que pesquisar informando o email inteiro ou parte dele a melhor forma é indexar
essa coluna (email) para que a pesquisa seja mais performática.

## Order.find_by_date_range

O problema encontrado foi uma pesquisa em um intervalo grande de datas.
A princípio eu troquei os operados >= e <= pelo BETWEEN o que trouxe uma
diferença pequena de performance, contudo como o intervalo de datas pode não ter
um limite optei por criar um índice na coluna order_date.

## Order.calculate_daily_revenue

Mais uma vez um cálculo tomando tempo de processamento sendo que poderia ser
feito no banco.

## Order.count_orders_by_city

Nesse caso é preciso contar o número de Orders por cidade mas isso está
ocupando muito processamento no back-end sendo que pode simplesmente ser
feito usando recursos do banco de dados (GROUP BY). Desse modo em uma única consulta
produz o resultado esperado.

## Order.search_by_customer

Em um primeiro momento pensei em tornar o campo email como único (UNIQUE INDEX) porém
percebi que isso quebraria a regra de negócio pois para cada novo pedido o cliente necessitaria
ter um email novo o que não faz o menor sentido. Portanto abandonei essa ideia e adicionei um
índice semelhante ao da coluna order_date

# Resultados


