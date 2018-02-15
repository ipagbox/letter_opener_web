# frozen_string_literal: true

require 'pry-byebug'
require 'combustion'
Combustion.initialize! :action_controller

require 'spec_helper'
require 'rspec/rails'
require 'shoulda-matchers'

RSpec.configure(&:infer_spec_type_from_file_location!)
