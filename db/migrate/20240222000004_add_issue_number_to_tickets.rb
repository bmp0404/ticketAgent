# frozen_string_literal: true

class AddIssueNumberToTickets < ActiveRecord::Migration[7.1]
  def up
    return if column_exists?(:tickets, :issue_number)
    add_column :tickets, :issue_number, :integer, default: 0, null: false
    add_index :tickets, [:repo_identifier, :issue_number], unique: true, if_not_exists: true
  end

  def down
    remove_column :tickets, :issue_number, if_exists: true
  end
end
