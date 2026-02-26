# frozen_string_literal: true

class AddRepoIdentifierToTickets < ActiveRecord::Migration[7.1]
  def up
    unless column_exists?(:tickets, :repo_identifier)
      execute <<-SQL.squish
        ALTER TABLE tickets ADD COLUMN repo_identifier TEXT DEFAULT '';
      SQL
    end
    add_index :tickets, :repo_identifier, if_not_exists: true if column_exists?(:tickets, :repo_identifier)
    add_index :tickets, [:repo_identifier, :issue_number], unique: true, if_not_exists: true if column_exists?(:tickets, :repo_identifier) && column_exists?(:tickets, :issue_number)
  end

  def down
    remove_column :tickets, :repo_identifier, if_exists: true
  end
end
