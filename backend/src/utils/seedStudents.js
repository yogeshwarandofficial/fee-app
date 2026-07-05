require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const connectDB = require('../config/db');
const MasterConfig = require('../models/MasterConfig');
const Student = require('../models/Student');
const { generateStudentId } = require('./idGenerator');
const mockStudents = require('./mock_students_data');

async function getOrCreateConfig(type, name, parent_id = null) {
  if (!name) return null;
  const filter = { type, name: name.trim(), parent_id };
  let config = await MasterConfig.findOne(filter);
  if (!config) {
    config = await MasterConfig.create(filter);
    console.log(`Created new ${type}: ${name}`);
  }
  return config._id;
}

const seedStudents = async () => {
  try {
    await connectDB();
    console.log('Connected to DB. Starting seed...');

    let successCount = 0;
    let failCount = 0;

    for (const data of mockStudents) {
      try {
        // Validate required fields exist in mock data
        if (!data.full_name || !data.phone_number || !data.gradeName || !data.sectionName) {
          throw new Error(`Missing required fields for student: ${data.full_name || 'Unknown'}`);
        }

        // Validate phone number (must be 10 digits)
        const cleanPhone = data.phone_number.toString().replace(/\D/g, '');
        if (cleanPhone.length !== 10) {
          throw new Error(`Invalid phone number for ${data.full_name}: ${data.phone_number}`);
        }

        // 1. Resolve Grade ID
        const gradeId = await getOrCreateConfig('grade', data.gradeName);

        // 2. Resolve Section ID (using gradeId as parent)
        const sectionId = await getOrCreateConfig('section', data.sectionName, gradeId);

        // 3. Resolve Route ID (if provided)
        let routeId = null;
        if (data.routeName) {
          routeId = await getOrCreateConfig('route', data.routeName);
        }

        // Check if student already exists by phone & name to avoid duplicate seeding
        // Wait, students can share names. We just generate a new ID, but to prevent running this 10 times and getting 10x students:
        const exists = await Student.findOne({ phone_number: cleanPhone, full_name: data.full_name.trim() });
        if (exists) {
          console.log(`Skipping ${data.full_name} - already exists in DB.`);
          continue;
        }

        const student_id = await generateStudentId();

        // Calculate initial status
        let totalDue = 0;
        if (data.balances) {
          totalDue += (data.balances.tuition?.due || 0);
          totalDue += (data.balances.transport?.due || 0);
          totalDue += (data.balances.other?.due || 0);
        }
        const status = totalDue === 0 ? 'cleared' : 'pending';

        // Format balances safely
        const parsedBalances = {
          tuition: { paid: data.balances?.tuition?.paid || 0, due: data.balances?.tuition?.due || 0 },
          transport: { paid: data.balances?.transport?.paid || 0, due: data.balances?.transport?.due || 0 },
          other: { paid: data.balances?.other?.paid || 0, due: data.balances?.other?.due || 0 }
        };

        const newStudent = new Student({
          student_id,
          full_name: data.full_name.trim(),
          phone_number: cleanPhone,
          grade_id: gradeId,
          section_id: sectionId,
          transport_route_id: routeId,
          avatar_url: data.avatar_url || null,
          balances: parsedBalances,
          status
        });

        await newStudent.save();
        console.log(`✅ Seeded student: ${data.full_name} (${student_id})`);
        successCount++;
      } catch (err) {
        console.error(`❌ Failed to seed student ${data.full_name}: ${err.message}`);
        failCount++;
      }
    }

    console.log(`\nSeed completed! Successfully added: ${successCount}. Failed: ${failCount}`);

  } catch (err) {
    console.error('Fatal Error during seed:', err);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
};

seedStudents();
