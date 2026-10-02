class CreateMocks < ActiveRecord::Migration[7.1]
  def change
    create_table :mocks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :paper_key, null: false
      t.integer :status, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :deadline_at, null: false
      t.datetime :finished_at
      t.integer :score, null: false, default: 0
      t.timestamps
    end
    # NOTE: 0 = Mock.statuses[:in_progress] — keep in sync if enum is reordered
    add_index :mocks, :user_id, unique: true, where: "status = 0", name: "index_mocks_one_in_progress_per_user"

    create_table :mock_challenges do |t|
      t.references :mock, null: false, foreign_key: true
      t.references :challenge, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :code
      t.datetime :solved_at
      t.timestamps
    end
    add_index :mock_challenges, [:mock_id, :challenge_id], unique: true
    add_index :mock_challenges, [:mock_id, :position], unique: true
  end
end
