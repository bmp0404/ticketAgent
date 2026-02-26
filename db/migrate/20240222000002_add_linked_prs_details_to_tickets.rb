# frozen_string_literal: true

class AddLinkedPrsDetailsToTickets < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets, :linked_prs_details, :jsonb, default: [], null: false
  end
end
