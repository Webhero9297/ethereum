// module.exports = {
//   networks: {
//     development: {
//       host: "localhost",
//       port: 8545,
//       network_id: "*" // Match any network id
//     }
//   }
// };
module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    }
  },
  build: {
    "index.html" : "index.html",
    "app.js" : [ "javascripts/app.js"],
    "app.css" : ["stylesheets/app.css"],
    "images/" : "images"
  },
  rpc: {
    host: "localhost",
    port: 8545
  }
};
