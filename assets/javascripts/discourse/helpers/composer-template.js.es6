import { registerUnbound } from "discourse-common/lib/helpers";

registerUnbound("rstudio-topic-url", (topic) => {
  return topic.linked_post_number
    ? topic.urlForPostNumber(topic.linked_post_number)
    : topic.get("lastUnreadUrl");
});

registerUnbound("rstudio-topic-date", (date) => {
  if (!date) return;

  return moment(date).format("YYYY-MM-DD HH:mm");
});
