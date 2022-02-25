# frozen_string_literal: true

module LetterOpenerWeb
  class LettersController < ApplicationController
    if Rails::VERSION::STRING < '4'
      class << self
        alias before_action before_filter
      end
    end

    before_action :check_style, only: [:show]
    before_action :load_letter, only: %i[show attachment destroy]

    def index
      @letters = Letter.search
    end

    def search
      @letters = Letter.query(params[:q]) if params.key?(:q)

      render :index
    end

    def show
      text = @letter.send("#{params[:style]}_text")
                    .gsub(/"plain\.html"/, "\"#{letter_path(id: @letter.id, style: 'plain')}\"")
                    .gsub(/"rich\.html"/, "\"#{letter_path(id: @letter.id, style: 'rich')}\"")

      if Rails::VERSION::STRING < '4.1'
        render inline: text
      else
        render html: text.html_safe
      end
    end

    def attachment
      filename = "#{params[:file]}.#{params[:format]}"
      file     = @letter.attachments[filename]

      return render inline: 'Attachment not found!', status: 404 unless file.present?
      send_file(file, filename: filename, disposition: 'inline')
    end

    def clear
      Letter.destroy_all
      redirect_to letters_url
    end

    def destroy
      @letter.delete
      redirect_to letters_url
    end

    private

    def check_style
      params[:style] = 'rich' unless %w[plain rich].include?(params[:style])
    end

    def load_letter
      @letter = Letter.find(params[:id])
      head :not_found unless @letter.exists?
    end

    def routes
      LetterOpenerWeb.railtie_routes_url_helpers
    end
  end
end
