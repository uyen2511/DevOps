const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

const MONGO_URI = 'mongodb://admin:secret@mongodb:27017/devops?authSource=admin';
const UPLOAD_DIR = '/app/phase1/src/public/uploads';

async function fixImages() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected to MongoDB (container)');

    // Đọc danh sách file trong thư mục uploads
    const files = fs.readdirSync(UPLOAD_DIR);
    console.log('📁 Files in uploads:', files);

    // Tạo mapping từ tên sản phẩm sang file
    const productToFile = {
      'iPhone 14 Pro Max': files.find(f => f.toLowerCase().includes('ip14pro')),
      'iPhone SE': files.find(f => f.toLowerCase().includes('ipse') || f.toLowerCase().includes('iphone12')),
      'MacBook Pro': files.find(f => f.toLowerCase().includes('macpro')),
      'MacBook Air': files.find(f => f.toLowerCase().includes('macair')),
      'iPad Pro': files.find(f => f.toLowerCase().includes('ipadpro')),
      'iPad': files.find(f => f.toLowerCase().includes('ipad') && !f.includes('pro')),
      'Apple Watch': files.find(f => f.toLowerCase().includes('watch')),
      'AirPods Pro': files.find(f => f.toLowerCase().includes('airpodpro')),
      'HomePod': files.find(f => f.toLowerCase().includes('homepod')),
    };

    // Lấy tất cả sản phẩm
    const products = await mongoose.connection.db.collection('products').find({}).toArray();
    console.log(`📦 Found ${products.length} products`);

    for (const product of products) {
      let newImagePath = null;
      
      // Tìm file phù hợp dựa trên tên sản phẩm
      for (const [key, filename] of Object.entries(productToFile)) {
        if (product.name.includes(key) && filename) {
          newImagePath = '/uploads/' + filename;
          break;
        }
      }

      // Nếu không tìm được, dùng file mặc định
      if (!newImagePath) {
        // Thử tìm file có tên tương tự
        const possibleFile = files.find(f => 
          product.name.toLowerCase().includes(f.replace('.JPG', '').toLowerCase())
        );
        if (possibleFile) {
          newImagePath = '/uploads/' + possibleFile;
        } else {
          // Dùng file đầu tiên có .JPG
          const firstJpg = files.find(f => f.endsWith('.JPG'));
          if (firstJpg) {
            newImagePath = '/uploads/' + firstJpg;
            console.log(`⚠️  Using default for ${product.name}: ${firstJpg}`);
          }
        }
      }

      if (newImagePath) {
        // Cập nhật database
        await mongoose.connection.db.collection('products').updateOne(
          { _id: product._id },
          { $set: { imageUrl: newImagePath } }
        );
        console.log(`✅ ${product.name}: ${product.imageUrl || 'no image'} -> ${newImagePath}`);
      } else {
        console.log(`❌ ${product.name}: no matching file found`);
      }
    }

    console.log('🎉 Done!');
  } catch (err) {
    console.error('❌ Error:', err);
  } finally {
    await mongoose.disconnect();
  }
}

fixImages();
