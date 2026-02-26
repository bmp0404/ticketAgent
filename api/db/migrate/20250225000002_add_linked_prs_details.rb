# frozen_string_literal: true

class AddLinkedPrsDetails < ActiveRecord::Migration[7.1]
  def change
    return if column_exists?(:tickets, :linked_prs_details)

    add_column :tickets, :linked_prs_details, :jsonb, default: [], null: false
  end
end
