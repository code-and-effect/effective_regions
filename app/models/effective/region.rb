module Effective
  class Region < ActiveRecord::Base
    self.table_name = EffectiveRegions.regions_table_name.to_s

    belongs_to :regionable, :polymorphic => true

    structure do
      title             :string, :validates => [:presence]
      content           :text
      snippets          :text

      timestamps
    end

    serialize :snippets, HashWithIndifferentAccess

    scope :global, -> { where('regionable_type IS NULL').where('regionable_id IS NULL') }

    def snippets
      self[:snippets] || HashWithIndifferentAccess.new()
    end

    # Hash of the Snippets objectified
    #
    # Returns a Hash of {'snippet_1' => CurrentUserInfo.new(snippets[:key]['options'])}
    def snippet_objects
      @snippet_objects ||= snippets.map do |key, snippet|
        if snippet['name']
          klass = "Effective::Snippets::#{snippet['name'].classify}".safe_constantize
          klass.new((snippet['options'] || {}).merge!(:region => self, :id => key)) if klass
        end
      end.compact
    end

    def global?
      self.regionable_id == nil && self.regionable_type == nil
    end

  end
end




