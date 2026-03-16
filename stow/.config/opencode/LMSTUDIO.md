# LM Studio Provider para OpenCode

## Configuração

O OpenCode está configurado para usar **LM Studio** como provider de modelos de IA.

### Detalhes Técnicos

- **Provider ID**: `lmstudio`
- **Tipo**: OpenAI-Compatible
- **Endpoint**: `http://192.168.68.60:1234/v1`
- **Modelo**: `local`
- **SDK**: `@ai-sdk/openai-compatible`

### Arquivo de Configuração

```json
{
  "provider": {
    "lmstudio": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "LM Studio",
      "options": {
        "baseURL": "http://192.168.68.60:1234/v1"
      },
      "models": {
        "local": {
          "name": "LM Studio (Local)"
        }
      }
    }
  }
}
```

## Como Usar

1. Certifique-se que LM Studio está rodando em `192.168.68.60:1234`
2. OpenCode carregará automaticamente o provider `lmstudio`
3. Use o modelo `lmstudio/local` nas suas aplicações

## Verificação

Para testar se está funcionando:

```bash
curl http://192.168.68.60:1234/v1/models
```

Deve retornar os modelos disponíveis no LM Studio.

## Notas

- LM Studio é um servidor local de modelos de IA com suporte a GPU
- A API é compatível com OpenAI `/v1/chat/completions`
- Nenhuma chave de API é necessária (local)

## OpenCode no container (claudinho sandbox)

Quando o opencode roda dentro do container (`make claudio-code`), a config é montada de `~/.config/opencode` do host. O sandbox usa `network_mode: host`, então o LM Studio no host é acessível no mesmo endereço (ex.: `192.168.68.60:1234` ou `127.0.0.1:1234`). Nada precisa mudar no `opencode.json`.
