module ComfortableMexicanSofa::HasRevisions
  
  def self.included(base)
    base.send :extend, ClassMethods
  end
  
  module ClassMethods
    
    def cms_has_revisions_for(*fields)
      
      include ComfortableMexicanSofa::HasRevisions::InstanceMethods
      
      attr_accessor :revision_data
      attr_accessor :skip_create_revision
      
      has_many :revisions,
        :as         => :record,
        :dependent  => :destroy,
        :class_name => 'Comfy::Cms::Revision'
      
      before_save :prepare_revision
      after_save  :create_revision
      
      define_method(:revision_fields) do
        fields.collect(&:to_s)
      end
    end
  end
  
  module InstanceMethods

    # Preparing revision data. A bit of a special thing to grab page blocks
    def save_revision_data(only_if_changed=true, method_pattern='%s')
      # return if self.new_record?
      if !only_if_changed ||
         ((self.respond_to?(:blocks_attributes_changed) && self.blocks_attributes_changed) || !(self.changed & revision_fields).empty?)
        self.revision_data = revision_fields.inject({}) do |c, field|
          c[field] = self.send(method_pattern % field)
          c
        end
      end
    end
    
    def prepare_revision
      return if self.new_record?
      self.save_revision_data(true, '%s_was')
    end
    
    def prepare_inverse_revision
      return if self.new_record?
      self.save_revision_data(true)
    end
    
    def prepare_inverse_revision!
      self.save_revision_data(false, '%s')
    end
    
    # Revision is created only if relevant data changed
    def create_revision
      return unless self.revision_data
      return if self.skip_create_revision
      
      # creating revision
      if ComfortableMexicanSofa.config.revisions_limit.to_i != 0
        self.revisions.create!(:data => self.revision_data)
      end
      
      # blowing away old revisions
      ids = [0] + self.revisions.limit(ComfortableMexicanSofa.config.revisions_limit.to_i).collect(&:id)
      self.revisions.where('id NOT IN (?)', ids).destroy_all
    end

    # Assigning whatever is found in revision data and attemptint to save the object
    def restore_from_revision(revision)
      return unless revision.record == self
      self.update_attributes!(revision.data)
    end

    def publish_scheduled_revision(revision)
      pub_rev_data = revision.data
      pub_rev_data['last_published_revision_id'] = revision.id
      pub_rev_data['scheduled_revision_id'] = nil
      pub_rev_data['scheduled_revision_datetime'] = nil
      self.update_attributes!(pub_rev_data)
    end
  end
end

ActiveRecord::Base.send :include, ComfortableMexicanSofa::HasRevisions