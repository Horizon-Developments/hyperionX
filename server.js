const {
	WebSocketServer
} = require("ws");
const ngrok = require("@ngrok/ngrok");

const authtoken = process.argv[2];
const domain = process.argv[3];
const owner_password = process.argv[4];
const client_password = process.argv[5];

if (!authtoken || !domain || !owner_password || !client_password) {
	process.exit(1);
}

const wss = new WebSocketServer({
	port: 58473
});
let wsOwner = null;
const clients = new Set();

const interval = setInterval(() => {
	wss.clients.forEach((ws) => {
		if (ws.isAlive === false) return ws.terminate();
		ws.isAlive = false;
		ws.ping(Date.now().toString());
	});
}, 15000);

wss.on("connection", (ws) => {
	ws.isAlive = true;
	ws.authenticated = false;
	ws.latency = 0;

	ws.on("pong", (data) => {
		ws.isAlive = true;
		const sentTime = parseInt(data.toString());
		if (!isNaN(sentTime)) ws.latency = Date.now() - sentTime;
	});

	ws.send("challenge");

	const authTimeout = setTimeout(() => {
		if (!ws.authenticated) ws.close(4003);
	}, 3000);

	ws.on("message", (data) => {
		if (!ws.authenticated) {
			let parsed;
			try {
				parsed = JSON.parse(data);
			} catch {
				return ws.close(1007);
			}

			const {
				type,
				password
			} = parsed;

			if (type === "RhWuvwF3FZ") {
				if (password !== owner_password) return ws.close(4001);
				clearTimeout(authTimeout);
				ws.authenticated = true;
				if (wsOwner) wsOwner.close(1000);
				wsOwner = ws;

				ws.send(JSON.stringify({
					status: "ok",
					role: "owner"
				}));

				ws.on("message", (data) => {
					for (const client of clients) {
						if (client.readyState === 1) {
							client.send(data, (err) => {
								if (err) clients.delete(client);
							});
						}
					}
				});

				ws.on("close", () => {
					if (wsOwner === ws) wsOwner = null;
				});

			} else if (type === "client") {
				if (password !== client_password) return ws.close(4002);
				clearTimeout(authTimeout);
				ws.authenticated = true;
				clients.add(ws);

				ws.send(JSON.stringify({
					status: "ok",
					role: "client"
				}));

				ws.on("close", () => clients.delete(ws));

			} else {
				ws.close(1008);
			}

			return;
		}
	});

	ws.on("error", () => {});
});

(async () => {
	await ngrok.forward({
		addr: 58473,
		authtoken,
		domain
	});
	const toHex = (str) => Buffer.from(str).toString("hex");
	console.log("HyperionX Active");
	console.log("\nOwner token:\n");
	console.log(toHex(JSON.stringify({
		url: ownerUrl,
		type: "RhWuvwF3FZ",
		password: owner_password
	})));
	console.log("\nClient token:\n");
	console.log(toHex(JSON.stringify({
		url: clientUrl,
		type: "client",
		password: client_password
	})));
	console.log("\nThese URLs won't change unless you change script arguments.");
	console.warn("DO NOT SHARE YOUR PASSWORDS.");
})();

wss.on("close", () => clearInterval(interval));