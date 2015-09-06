class UpgradeTo1129 < ActiveRecord::Migration
  def self.up
    add_column :comfy_cms_pages, :is_withdrawn, :boolean, :default => false
    add_column :comfy_cms_pages, :newest_draft_timestamp, :datetime, :null => true

    create_table :comfy_cms_variants, :force => true do |t|
      t.belongs_to :site
      t.string  :label
      t.string  :hostname
      t.integer :hierarchy
      t.boolean :is_default, default: false
      t.timestamps
    end
    add_index :comfy_cms_variants, :label
    add_column :comfy_cms_blocks, :variantable_id, :integer
    add_column :comfy_cms_blocks, :variantable_type, :string
  end

  def self.down
    remove_column :comfy_cms_pages, :is_withdrawn, :boolean
    remove_column :comfy_cms_pages, :newest_draft_timestamp, :datetime

    remove_column :comfy_cms_blocks, :variantable_id, :integer
    remove_column :comfy_cms_blocks, :variantable_type, :string
    remove_index :comfy_cms_variants, :label
    drop_table :comfy_cms_variants
  end
end
