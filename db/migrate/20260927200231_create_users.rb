class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email
      t.integer :role

      t.timestamps
    end
  end
end
