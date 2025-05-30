const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');

const dynamo = new AWS.DynamoDB.DocumentClient();
const JWT_SECRET = process.env.JWT_SECRET;
const TABLE_NAME = process.env.CLIENTS_TABLE;

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const cpf = body.cpf?.replace(/\D/g, ''); // limpa máscara se vier com pontos

    const payload = {
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 60 * 60, // 1 hora
    };

    if (cpf) {
      const client = await findClientByCPF(cpf);

      if (client) {
        payload.sub = cpf;
        payload.name = client.name;
        payload.email = client.email;
      } else {
        payload.sub = cpf;
        payload.needs_registration = true;
      }
    } else {
      payload.needs_registration = true;
    }

    const token = jwt.sign(payload, JWT_SECRET);

    return {
      statusCode: 200,
      body: JSON.stringify({ token }),
    };
  } catch (err) {
    console.error('Erro na Lambda de autenticação:', err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Erro interno na autenticação' }),
    };
  }
};

async function findClientByCPF(cpf) {
  const params = {
    TableName: TABLE_NAME,
    Key: { cpf },
  };

  const result = await dynamo.get(params).promise();
  return result.Item;
}
