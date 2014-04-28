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

end
