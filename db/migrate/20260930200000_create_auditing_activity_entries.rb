class CreateAuditingActivityEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :auditing_activity_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :subject, null: false
      t.json :details, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :auditing_activity_entries, :occurred_at
    add_index :auditing_activity_entries, :action
  end
end
