// backend/middlewares/upload_handler.js

import multer from 'multer'; 
import { v2 as cloudinary } from 'cloudinary'; 
import streamifier from 'streamifier'; 


// Configuracion de multer
const upload = multer({ storage: multer.memoryStorage() });


/**
 * Middleware genérico que sube el archivo a Cloudinary y adjunta la URL al request.
 * * @param {string} folderName -
 * @param {string} publicId - 
 */
const genericUploadHandler = (folderName, publicId = null) => {
    return [
        upload.single('imageFile'), 
        async (req, res, next) => {
            try {
                const file = req.file; 

                if (!file) {
                    return res.status(400).json({ error: 'No se ha proporcionado ningún archivo.' });
                }

                // 1. Opciones de Cloudinary
                const options = {
                    folder: folderName,
                    overwrite: publicId !== null, 
                };
                if (publicId) {
                    options.public_id = publicId;
                }
                
                // 2. Subir a Cloudinary
                const uploadResult = await new Promise((resolve, reject) => {
                    const stream = cloudinary.uploader.upload_stream(
                        options,
                        (error, result) => {
                            if (result) {
                                resolve(result);
                            } else {
                                reject(error);
                            }
                        }
                    );
                    streamifier.createReadStream(file.buffer).pipe(stream);
                });

                // Adjuntar resultado al request
                req.uploadedFile = {
                    url: uploadResult.secure_url,
                    public_id: uploadResult.public_id,
                };

                next(); 

            } catch (error) {
                console.error(`Error al subir la imagen a Cloudinary en la carpeta ${folderName}:`, error);
                res.status(500).json({ error: 'Error interno del servidor al procesar la imagen.' });
            }
        }
    ];
};
export { genericUploadHandler }; 

