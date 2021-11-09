library(magrittr)

readr::read_file("./content/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br.markdown") %>% 
  stringr::str_replace_all("&lt;U\\+(.+?)&gt;","&#x\\1;") %>% 
  readr::write_file("./content/posts/2019-10-12-analise-de-sentimentos-via-emojis-em-chat-do-whatsapp/index.pt-br.markdown")
