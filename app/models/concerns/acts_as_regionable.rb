module ActsAsRegionable
  extend ActiveSupport::Concern

  module Base
    def acts_as_regionable(*options)
      @acts_as_regionable_opts = options || []
      include ::ActsAsRegionable
    end
  end

  included do
    has_many :regions, :as => :regionable, :class_name => 'Effective::Region', :dependent => :delete_all, :autosave => true
  end

  module ClassMethods
  end

  def acts_as_regionable
    true
  end

  def region(title)
    title = title.to_s
    regions.to_a.find { |region| region.title == title } || regions.build(title: title)
  end

  def snippet_objects(klass = nil)
    objs = regions.map { |region| region.snippet_objects }.flatten

    if klass
      objs = objs.select { |obj| obj.class == klass }
    else
      objs
    end

  end

end

