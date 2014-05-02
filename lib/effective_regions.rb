require "effective_regions/engine"
require "effective_regions/version"

module EffectiveRegions
  mattr_accessor :regions_table_name
  mattr_accessor :authorization_method

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &EffectiveRegions.authorization_method)
    true
  end

  # Returns a Snippet.new() for every class in the /app/effective/snippets/* directory
  def self.snippets
    Rails.env.development? ? read_snippets : (@@snippets ||= read_snippets)
  end

  # Returns a Template.new() for every class in the /app/effective/templates/* directory
  def self.templates
    Rails.env.development? ? read_templates : (@@templates ||= read_templates)
  end

  private

  def self.read_snippets
    snippets = []

    begin
      # Reversing here so the app's templates folder has precedence.

      files = ApplicationController.view_paths.map { |path| Dir["#{path}/effective/snippets/**"] }.flatten.reverse

      files.each do |file|
        snippet = File.basename(file)
        snippet = snippet[1...snippet.index('.') || snippet.length] # remove the _ and .html.haml
        if (klass = "Effective::Snippets::#{snippet.try(:classify)}".safe_constantize)
          snippets << klass unless snippets.include?(klass)
        end
      end

      snippets.map { |klass| klass.new() rescue nil }.compact
    rescue => e
      []
    end
  end

  def self.read_templates
    templates = []

    begin
      # Reversing here so the app's templates folder has precedence.

      files = ApplicationController.view_paths.map { |path| Dir["#{path}/effective/templates/**"] }.flatten.reverse

      files.each do |file|
        template = File.basename(file)
        template = template[1...template.index('.') || template.length] # remove the _ and .html.haml
        if (klass = "Effective::Templates::#{template.try(:classify)}".safe_constantize)
          templates << klass unless templates.include?(klass)
        end
      end

      templates.map { |klass| klass.new() rescue nil }.compact
    rescue => e
     []
    end
  end

end
