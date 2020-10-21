# frozen_string_literal: true

ComposerTemplate::Engine.routes.draw do
  post "clear-all/:category_id" => "admin#clear_all", constraints: AdminConstraint.new
end

Discourse::Application.routes.append do
  mount ComposerTemplate::Engine, at: 'rstudio-composer-template'
end