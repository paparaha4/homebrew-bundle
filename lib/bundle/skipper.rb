# frozen_string_literal: true

require "hardware"

module Bundle
  module Skipper
    class << self
      def skip?(entry, silent: false)
        if Hardware::CPU.arm? && entry.type == :brew && entry.name.exclude?("/") &&
           !BrewDumper.formulae_by_full_name(entry.name)[:bottled_or_disabled]
          puts Formatter.warning "Skipping #{entry.name} (no bottle for Apple Silicon)" unless silent
          return true
        end

        return true if skipped_entries[:tap]&.any? do |tap|
          prefix = "#{tap}/"
          entry.name.start_with?(prefix) || entry.options[:full_name]&.start_with?(prefix)
        end

        entry_type_skips = Array(skipped_entries[entry.type])
        return false if entry_type_skips.empty?

        # Check the name or ID particularly for Mac App Store entries where they
        # can have spaces in the names (and the `mas` output format changes on
        # occasion).
        entry_ids = [entry.name, entry.options[:id]&.to_s].compact
        return false if (entry_type_skips & entry_ids).empty?

        puts Formatter.warning "Skipping #{entry.name}" unless silent
        true
      end
      alias generic_skip? skip?

      def skip(entry)
        (skipped_entries[entry.type] ||= []) << entry.name
      end

      private

      def skipped_entries
        return @skipped_entries if @skipped_entries

        @skipped_entries = {}
        [:brew, :cask, :mas, :tap, :whalebrew].each do |type|
          @skipped_entries[type] =
            ENV["HOMEBREW_BUNDLE_#{type.to_s.upcase}_SKIP"]&.split
        end
        @skipped_entries
      end
    end
  end
end

require "bundle/extend/os/skipper"
