# frozen_string_literal: true

# If Supabase table was created with id as UUID, change to TEXT for "owner/repo#number" format.
# Irreversible.
class ChangeTicketsIdToText < ActiveRecord::Migration[7.1]
  def up
    return unless column_exists?(:tickets, :id)

    # Only alter if current type is not string/text
    conn = connection
    col = conn.columns(:tickets).find { |c| c.name == "id" }
    return if col && col.sql_type&.downcase&.include?("text")

    execute <<-SQL.squish
      ALTER TABLE tickets ALTER COLUMN id DROP DEFAULT;
      ALTER TABLE tickets ALTER COLUMN id TYPE TEXT USING id::TEXT;
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
