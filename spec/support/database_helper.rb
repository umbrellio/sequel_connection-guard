# frozen_string_literal: true

class DatabaseHelper
  DATABASE_URL = ENV["DB_URL"] || "postgres://localhost/sequel_connection_guard"
  MAX_CONNECTIONS = Sequel.connect(DATABASE_URL) do |db|
    db.fetch("SHOW max_connections").first.fetch(:max_connections).to_i
  end

  def initialize
    @connections = []
  end

  # Opposite of #turn_off.
  # Closes all open connections which allows new connections to be established.
  def turn_on
    connections.each(&:disconnect)
    @connections = []
  end

  # Overwhelms the database with open connections so that no new connections could be established.
  # For purposes of this extension, this is identical to any kind of connection failure.
  def turn_off
    MAX_CONNECTIONS.times do
      connections << Sequel.connect(DATABASE_URL)
    end
  rescue Sequel::DatabaseConnectionError
  end

  def migrate_up
    Sequel.connect(DATABASE_URL) do |db|
      Sequel::TimestampMigrator.new(db, "spec/fixtures/migrations").run
    end
  end

  def migrate_down
    Sequel.connect(DATABASE_URL) do |db|
      db.tables.each { |t| db.drop_table?(t, cascade: true) }
    end
  end

  def clear
    Sequel.connect(DATABASE_URL) do |db|
      db.tables.each { |t| db.run("DELETE FROM #{t} WHERE true") }
    end
  end

  private

  attr_accessor :connections
end
