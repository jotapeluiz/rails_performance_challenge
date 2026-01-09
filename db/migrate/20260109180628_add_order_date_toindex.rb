class AddOrderDateToindex < ActiveRecord::Migration
  def change
    add_index(:orders, :order_date)
  end
end
