var fs = require("fs");
var path = require('path');

// file is included here:
eval(fs.readFileSync('js/musl.parser.readable.js')+'');

const processMusl = function (filename, onFinished) {
  let fromPath = path.join(folderSource, filename);
  let toPath = path.join(folderDestination, filename) + '.json';
  let copyPath = path.join(folderFinished, filename);
  //.replace(".msl", "").replace(".musl", "").append(".json")

  fs.readFile(fromPath, 'utf-8', function(err, muslContent) {
    if (err) {
      console.error("could not read the file ", fromPath);
    }

    console.log("Processing MUSL ----->", fromPath);
    let muslJson = musl.Parser(muslContent, true);

    fs.writeFile(toPath, JSON.stringify(muslJson), function(err) {
      if (err) {
        console.error("could not create file ", err);
        onFinished();
      } else {
        fs.rename(fromPath, copyPath, function(err) {
          if (err) {
            console.error("Failed ", err);
          } else {
            console.log("OK！ ");
          }
          onFinished();
        });
      }
    });
  });
}

const eachOfSeries = function (series, handler) {
  const getOnePromise = function(item) {
    return new Promise(function(resolve, reject) {
      handler(item, resolve);
    });
  };

  let chain = Promise.resolve();

  series.forEach(function(item) {
    chain = chain.then(function() {
      return getOnePromise(item);
    });
  });
};

const folderSource = path.join(__dirname, "source");
const folderDestination = path.join(__dirname, "destination");
const folderFinished = path.join(__dirname, "finished");

fs.readdir(folderSource, function(error, fileNames){
  if(error) {
    console.error("could not list the folder", error);
  }

  // fileNames.forEach(processMusl);
  eachOfSeries(fileNames, processMusl);
});
