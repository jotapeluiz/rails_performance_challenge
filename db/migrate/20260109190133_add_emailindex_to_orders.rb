class AddEmailindexToOrders < ActiveRecord::Migration
  def change
    add_index(:orders, :customer_email)
  end
end
