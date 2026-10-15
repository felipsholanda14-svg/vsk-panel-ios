# VSK Panel PWA para iPhone

## Publicar e instalar
1. Publique o conteúdo desta pasta em hospedagem estática com HTTPS (por exemplo, Vercel, Netlify ou GitHub Pages).
2. Abra o URL no Safari do iPhone.
3. Toque em Compartilhar > Adicionar à Tela de Início > Adicionar.

## Testar localmente
Na pasta do projeto, execute `python -m http.server 8000` e abra `http://localhost:8000`. Service workers funcionam em localhost ou HTTPS.

## Funcionalidades
Login local com validação, ajustes persistentes via localStorage, criação/carregamento/exclusão de perfis, mira personalizável e cache offline via service worker.

O login é local e não autentica em servidor. Não use uma senha real. A mira aparece apenas dentro do aplicativo.
