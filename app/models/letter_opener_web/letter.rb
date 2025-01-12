# frozen_string_literal: true

module LetterOpenerWeb
  class Letter
    attr_reader :id, :sent_at

    EMPTY_ARRAY = [].freeze

    def self.letters_location
      @letters_location ||= LetterOpenerWeb.config.letters_location
    end

    def self.letters_location=(directory)
      LetterOpenerWeb.configure { |config| config.letters_location = directory }
      @letters_location = nil
    end

    def self.search
      letters = Dir.glob("#{LetterOpenerWeb.config.letters_location}/*").map do |folder|
        new(id: File.basename(folder), sent_at: File.mtime(folder))
      end
      letters.sort_by(&:sent_at).reverse
    end

    def self.find(id)
      new(id: id)
    end

    def self.query(query)
      return EMPTY_ARRAY if query.blank?

      letters = search

      letters.select! do |letter|
        File.open("#{LetterOpenerWeb.config.letters_location}/#{letter.id}/#{letter.default_style}.html") do |file|
          file.each_line.find { |line| line =~ /#{query}/i }
        end.present?
      end

      letters
    end

    def self.destroy_all
      FileUtils.rm_rf(LetterOpenerWeb.config.letters_location)
    end

    def initialize(params)
      @id      = params.fetch(:id)
      @sent_at = params[:sent_at]
    end

    def plain_text
      @plain_text ||= adjust_link_targets(read_file(:plain))
    end

    def rich_text
      @rich_text ||= adjust_link_targets(read_file(:rich))
    end

    def to_param
      id
    end

    def default_style
      style_exists?('rich') ? 'rich' : 'plain'
    end

    def default_text
      @default_test ||= adjust_link_targets(read_file(default_style))
    end

    def attachments
      @attachments ||= Dir["#{base_dir}/attachments/*"].each_with_object({}) do |file, hash|
        hash[File.basename(file)] = File.expand_path(file)
      end
    end

    def delete
      FileUtils.rm_rf("#{LetterOpenerWeb.config.letters_location}/#{id}")
    end

    def exists?
      File.exist?(base_dir)
    end

    def subject
      @subject ||= default_text.scan(%r{<dt>Subject:</dt>[^<]*<dd><strong>([^>]+)</strong>}).last.first
    end

    private

    def base_dir
      "#{LetterOpenerWeb.config.letters_location}/#{id}"
    end

    def read_file(style)
      File.read("#{base_dir}/#{style}.html")
    end

    def style_exists?(style)
      File.file?("#{base_dir}/#{style}.html")
    end

    def adjust_link_targets(contents)
      # We cannot feed the whole file to an XML parser as some mails are
      # "complete" (as in they have the whole <html> structure) and letter_opener
      # prepends some information about the mail being sent, making REXML
      # complain about it
      contents.scan(%r{<a\s[^>]+>(?:.|\s)*?</a>}).each do |link|
        fixed_link = fix_link_html(link)
        xml        = REXML::Document.new(fixed_link).root
        next if xml.attributes['href'] =~ /(plain|rich).html/
        xml.attributes['target'] = '_blank'
        xml.add_text('') unless xml.text
        contents.gsub!(link, xml.to_s)
      end
      contents
    end

    def fix_link_html(link_html)
      # REFACTOR: we need a better way of fixing the link inner html
      link_html.dup.tap do |fixed_link|
        fixed_link.gsub!('<br>', '<br/>')
        fixed_link.scan(/<img(?:[^>]+?)>/).each do |img|
          fixed_img = img.dup
          fixed_img.gsub!(/>$/, '/>') unless img =~ %r{/>$}
          fixed_link.gsub!(img, fixed_img)
        end
      end
    end
  end
end
