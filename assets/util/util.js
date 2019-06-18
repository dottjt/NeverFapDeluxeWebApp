// const TurndownService = require('turndown')
// const turndownService = new TurndownService()

const fse = require('fs-extra');
const axios = require('axios');

const {
  generateWrapper,
  generateFullHead,
  generate,
} = require('./templates');

const getHead = (fileContents) => {
  const headRegex = new RegExp(/---(.|[\r\n])+---/);
  const head = fileContents.match(headRegex)[0];

  const rawWithHTMLContent = fileContents.split('---')[2];
  // const rawWithMDContent = turndownService.turndown(rawWithHTMLContent);
  // const content = filterContent(rawWithMDContent);

  return {
    head,
    content: rawWithHTMLContent,
  }
}

const generateEmails = async (collection, item, template_item, contentParser) => {
  const baseUrl = 'https://neverfapdeluxe.netlify.com/md';
  // const baseUrl = 'http://localhost:1313/md';

  const fileName = `${baseUrl}/${collection}/${item}.md`;
  const response = await axios.get(fileName);
  const file = response.data;
  const { head, content } = getHead(file.toString());

  const getHeadTitleRegex = /title: [\S ]+/ig
  const getHeadDayRegex = /day: [\S ]+/ig

  const title = head.match(getHeadTitleRegex)[0].split(':')[1].trim();
  const day = head.match(getHeadDayRegex)[0].split(':')[1].trim();

  // headParser.render(head);
  const parsedContent = contentParser.render(content);

  const headText = generateFullHead(day, title.replace(/"/g,""));
  const contentText = generateWrapper(parsedContent)

  const completeText = generate(headText, contentText);

  fse.outputFileSync(`templates/${collection}/${template_item}`, completeText, [{}]);

}

module.exports = {
  getHead,
  generateEmails,
}