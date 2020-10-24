# frozen_string_literal: true

class ComposerTemplate::AdminController < Admin::AdminController
  def clear_all
    category_id = params[:category_id]
    topics = Topic.where("
      topics.id in (
        select topic_id from topic_custom_fields
        where name = 'custom_embed'
        and value::boolean IS TRUE
      ) AND
      topics.category_id = ?
    ", category_id)
    
    if (topic_ids = topics.map(&:id)).any?
      Topic.transaction do
        Post.where(topic_id: topic_ids).destroy_all
        Topic.where(id: topic_ids).destroy_all
        TopicCustomField.where(topic_id: topic_ids, name: ['new_topic_form_data', 'custom_embed']).destroy_all
        TopicEmbed.where(topic_id: topic_ids).destroy_all
      end
    end

    render json: success_json
  end
end