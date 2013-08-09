module ActsAsRegionable
  extend ActiveSupport::Concern

  module ActiveRecord
    def acts_as_regionable(*options)
      @acts_as_regionable = options || []
      include ::ActsAsRegionable
    end
  end

  included do
    has_many :regions, :as => :regionable, :class_name => "Effective::Region", :dependent => :delete_all

    default_scope includes(:regions)
  end

  module ClassMethods
  end

  def acts_as_regionable
    true
  end

end

