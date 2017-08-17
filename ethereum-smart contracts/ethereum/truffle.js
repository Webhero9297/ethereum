module.exports = {
  networks: {
    live: {
      network_id: '1'
    },
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      host: '52.169.14.227',
      port: 30303,
      network_id: '*',
    }
  },
  skip_migrate: true,
  migrations_directory: "./ethereum/migrations"
};
