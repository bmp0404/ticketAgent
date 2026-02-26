# frozen_string_literal: true

class EnsureRepoIdentifierAndIssueNumber < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:tickets, :repo_identifier)
      add_column :tickets, :repo_identifier, :string, default: "", null: false
      add_index :tickets, :repo_identifier
    end

    unless column_exists?(:tickets, :issue_number)
      add_column :tickets, :issue_number, :integer, default: 0, null: false
      add_index :tickets, [:repo_identifier, :issue_number], unique: true
    end
  end
end
