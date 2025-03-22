const path = require("path");
const fs = require("fs");


const extAndMime = [
    {
        ext: "html",
        mimeType: "text/html",
    },
    {
        ext: "css",
        mimeType: "text/css",
    },
    {
        ext: "js",
        mimeType: "text/javascript",
    },
    {
        ext: "png",
        mimeType: "image/png",
    },
    {
        ext: "docx",
        mimeType: "application/msword",
    },
    {
        ext: "json",
        mimeType: "application/json",
    },
    {
        ext: "xml",
        mimeType: "application/xml",
    },
    {
        ext: "mp4",
        mimeType: "video/mp4",
    },
];

module.exports = (filePath) =>{
    const pathToStatic = filePath ? filePath : "static";
    console.log(`Using path: ${pathToStatic}`);

    return (req, res) => {
        if (req.method !== "GET") {
            res.writeHead(405, { "Content-Type": "text/plain" });
            res.end("Method Not Allowed");
            return;
        }

        const extension = path.extname(req.url).slice(1);

        if (!getMimeType(extension)) {
            res.writeHead(404, { "Content-Type": "text/plain" });
            res.end("This extension is not allowed");
            return;
        }

        const filePath = pathToStatic + req.url;

        console.log(filePath);

        fs.readFile(filePath, (error, data) => {
            if (error) {
                res.statusCode = 404;
                res.end("File not found");
            } else {
                const mimeType = getMimeType(extension);
                res.writeHead(200, { "Content-Type": mimeType });
                res.end(data);
            }
        });
    };

}
function getMimeType(extension) {
    const result = extAndMime.find((x) => x.ext == extension);
    return result ? result.mimeType : null; // Возвращаем null, если расширение не найдено
}
