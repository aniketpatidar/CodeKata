class CreateChallengeCompletions < ActiveRecord::Migration[7.1]
  def change
    create_table :challenge_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.datetime :completed_at

      t.timestamps
    end

    add_index :challenge_completions, [:user_id, :challenge_id], unique: true
  end
end
