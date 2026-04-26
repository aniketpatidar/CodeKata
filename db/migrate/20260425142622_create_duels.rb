class CreateDuels < ActiveRecord::Migration[7.1]
  def change
    create_table :duels do |t|
      t.references :challenger, foreign_key: { to_table: :users }
      t.references :opponent, foreign_key: { to_table: :users }
      t.references :challenge, foreign_key: true
      t.references :winner, foreign_key: { to_table: :users }, null: true
      t.integer :status, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :duels, [:challenger_id, :opponent_id, :status]
  end
end
