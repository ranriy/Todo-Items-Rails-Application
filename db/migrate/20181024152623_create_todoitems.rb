class CreateTodoitems < ActiveRecord::Migration
  def change
    create_table :todoitems do |t|
      t.string :title
      t.string :due_date
      t.text :description
      t.boolean :completed
      t.references :todolist, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
