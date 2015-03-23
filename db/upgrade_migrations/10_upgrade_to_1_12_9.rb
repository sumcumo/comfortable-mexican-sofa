class UpgradeTo1129 < ActiveRecord::Migration
  def self.up
    add_column :comfy_cms_pages, :is_withdrawn, :boolean, :default => false
  end

  def self.down
    remove_column :comfy_cms_pages, :is_withdrawn, :boolean
  end
end
