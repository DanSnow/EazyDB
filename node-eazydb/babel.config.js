module.exports = {
  presets: [
    [
      '@babel/preset-env',
      {
        targets: {
          node: 14,
        },
      },
    ],
  ],
  plugins: ['@babel/plugin-proposal-class-properties', '@babel/plugin-proposal-json-strings'],
}
