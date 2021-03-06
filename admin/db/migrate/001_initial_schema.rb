# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

class InitialSchema < ActiveRecord::Migration

  def self.up
  
    create_table "admins" do |t|
      t.column "username",   :string,   :limit => 32,  :default => "", :null => false
      t.column "password",   :string,   :limit => 32,  :default => "", :null => false
      t.column "email",      :string,   :limit => 128
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
  
    add_index "admins", ["username"], :name => "admins_uniq", :unique => true
  
    create_table "domains" do |t|
      t.column "domain",     :string,   :limit => 128
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
  
    add_index "domains", ["domain"], :name => "domain_uniq", :unique => true
  
    create_table "forwardings" do |t|
      t.column "domain_id",   :integer,                 :default => 0,  :null => false
      t.column "source",      :string,   :limit => 128, :default => "", :null => false
      t.column "destination", :text,                    :default => "", :null => false
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
    end
  
    create_table "policy" do |t|
      t.column "policy_name",               :string,  :limit => 32
      t.column "virus_lover",               :string,  :limit => 1
      t.column "spam_lover",                :string,  :limit => 1
      t.column "banned_files_lover",        :string,  :limit => 1
      t.column "bad_header_lover",          :string,  :limit => 1
      t.column "bypass_virus_checks",       :string,  :limit => 1
      t.column "bypass_spam_checks",        :string,  :limit => 1
      t.column "bypass_banned_checks",      :string,  :limit => 1
      t.column "bypass_header_checks",      :string,  :limit => 1
      t.column "spam_modifies_subj",        :string,  :limit => 1
      t.column "virus_quarantine_to",       :string,  :limit => 64
      t.column "spam_quarantine_to",        :string,  :limit => 64
      t.column "banned_quarantine_to",      :string,  :limit => 64
      t.column "bad_header_quarantine_to",  :string,  :limit => 64
      t.column "spam_tag_level",            :float
      t.column "spam_tag2_level",           :float
      t.column "spam_kill_level",           :float
      t.column "spam_dsn_cutoff_level",     :float
      t.column "addr_extension_virus",      :string,  :limit => 64
      t.column "addr_extension_spam",       :string,  :limit => 64
      t.column "addr_extension_banned",     :string,  :limit => 64
      t.column "addr_extension_bad_header", :string,  :limit => 64
      t.column "warnvirusrecip",            :string,  :limit => 1
      t.column "warnbannedrecip",           :string,  :limit => 1
      t.column "warnbadhrecip",             :string,  :limit => 1
      t.column "newvirus_admin",            :string,  :limit => 64
      t.column "virus_admin",               :string,  :limit => 64
      t.column "banned_admin",              :string,  :limit => 64
      t.column "bad_header_admin",          :string,  :limit => 64
      t.column "spam_admin",                :string,  :limit => 64
      t.column "spam_subject_tag",          :string,  :limit => 64
      t.column "spam_subject_tag2",         :string,  :limit => 64
      t.column "message_size_limit",        :integer
      t.column "banned_rulenames",          :string,  :limit => 64
    end
  
    create_table "users" do |t|
      t.column "domain_id",  :integer
      t.column "email",      :string,   :limit => 128, :default => "", :null => false
      t.column "name",       :string,   :limit => 128
      t.column "fullname",   :string,   :limit => 128
      t.column "password",   :string,   :limit => 32,  :default => "", :null => false
      t.column "home",       :string,                  :default => "", :null => false
      t.column "priority",   :integer,                 :default => 7,  :null => false
      t.column "policy_id",  :integer,  :limit => 10,  :default => 1,  :null => false
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
  
    create_table "vacations" do |t|
      t.column "user_id",    :integer, :limit => 10,                 :null => false
      t.column "subject",    :string,                :default => "", :null => false
      t.column "message",    :text
      t.column "expire",     :date
      t.column "created_at", :date
      t.column "updated_at", :date
    end
  
    create_table "version", :id => false do |t|
      t.column "version", :integer, :limit => 10, :null => false
    end
  
    create_table "whiteblacklists" do |t|
      t.column "user_id",  :integer, :limit => 10,                 :null => false
      t.column "priority", :integer, :limit => 10, :default => 7,  :null => false
      t.column "address",  :string,                :default => "", :null => false
      t.column "wb",       :string,  :limit => 10, :default => "", :null => false
    end

  end
  
  def self.down
    drop.table :admins
    drop.table :domains
    drop.table :policy
    drop.table :users
    drop.table :vacations
    drop.table :whiteblacklists
  end

end
