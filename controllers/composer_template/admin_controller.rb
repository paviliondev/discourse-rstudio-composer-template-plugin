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
      tcfs = TopicCustomField.where(topic_id: topic_ids, name: ['new_topic_form_data', 'custom_embed'])
      tembeds = TopicEmbed.where(topic_id: topic_ids)
      
      Topic.transaction do
        operator = TopicsBulkAction.new(current_user, topic_ids, :delete)
        operator.perform!
        tcfs.delete_all
        tembeds.delete_all
      end
    end

    render json: success_json
  end
end