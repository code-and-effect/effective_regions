require 'effective_ckeditor'
require 'effective_regions/engine'
require 'effective_regions/version'

module EffectiveRegions
  mattr_accessor :regions_table_name
  mattr_accessor :authorization_method
  mattr_accessor :before_save_method

  def self.setup
    yield self
  end

  def self.authorized?(controller, action, resource)
    if authorization_method.respond_to?(:call) || authorization_method.kind_of?(Symbol)
      raise Effective::AccessDenied.new() unless (controller || self).instance_exec(controller, action, resource, &authorization_method)
    end
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
    # Reversing here so the app's templates folder has precedence.
    files = ApplicationController.view_paths.map { |path| Dir["#{path}/effective/snippets/**"] }.flatten.reverse

    files.map do |file|
      snippet = File.basename(file)
      snippet = snippet[1...snippet.index('.') || snippet.length] # remove the _ and .html.haml

      "Effective::Snippets::#{snippet.try(:classify)}".constantize.new()
    end

  end

  def self.read_templates
    # Reversing here so the app's templates folder has precedence.
    files = ApplicationController.view_paths.map { |path| Dir["#{path}/effective/templates/**"] }.flatten.reverse

    files.map do |file|
      template = File.basename(file)
      template = template[1...template.index('.') || template.length] # remove the _ and .html.haml

      "Effective::Templates::#{template.try(:classify)}".constantize.new()
    end
  end

end
