# frozen_string_literal: true

class ChangeTicketsIdToText < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL.squish
      ALTER TABLE tickets ALTER COLUMN id DROP DEFAULT;
      ALTER TABLE tickets ALTER COLUMN id TYPE TEXT USING id::TEXT;
    SQL
  end

  def down
    # Reverting to UUID would require generating new UUIDs; leave as TEXT
    raise ActiveRecord::IrreversibleMigration
  end
end
