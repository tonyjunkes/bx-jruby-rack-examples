class CreateServiceDesk < ActiveRecord::Migration[7.2]
    def change
        create_table :agents do |t|
            t.string :name, null: false
        end
        create_table :customers do |t|
            t.string :name, null: false
            t.string :company, null: false
            t.string :email, null: false
            t.timestamps
        end
        create_table :tickets do |t|
            t.references :customer, null: false, foreign_key: true
            t.references :assignee, foreign_key: { to_table: :agents }
            t.string :title, null: false
            t.text :description, null: false
            t.string :priority, null: false, default: 'normal'
            t.string :status, null: false, default: 'open'
            t.timestamps
        end
        add_index :tickets, [:status, :priority]
        create_table :comments do |t|
            t.references :ticket, null: false, foreign_key: true
            t.references :agent, null: false, foreign_key: true
            t.text :body, null: false
            t.timestamps
        end
    end
end
