import { withPluginApi } from "discourse/lib/plugin-api";
import discourseComputed from "discourse-common/utils/decorators";

function initWithApi(api) {
  if (!Discourse.SiteSettings.composer_template_enabled) return;

  api.modifyClass("controller:composer", {
    @discourseComputed("model.action", "isWhispering", "model.editConflict", "model.showFields")
    saveLabel(modelAction, isWhispering, editConflict, showFields) {
      if (!showFields) return this._super(...arguments);

      return "composer_template.submit_article";
    },

    ntfCreateReply() {
      const result = [];

      this.ntfFields().forEach(f => {
        const val = this.getNtfVal(f.id);

        if (!val) return;

        result.push(val);
      });

      this.set("model.reply", result.join("\n\n"));
    }
  });
}

export default {
  name: "composer-template-plugin",
  after: "new-topic-form",
  initialize() {
    withPluginApi("0.8", initWithApi);
  }
};
