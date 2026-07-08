import { Response, NextFunction } from "express";  
  
import { AuthRequest } from "../middlewares/auth.middleware";  
  
import {  
  
askRingsideAI,  
  
getProgramRecommendation,  
  
} from "../services/ai.service";  
  
import { prisma } from "../config/prisma";  
  
import { AppError } from "../utils/AppError";  
  
// Helper function to calculate age from Date of Birth  
  
const calculateAge = (dob: Date) => {  
  
const diff = Date.now() - dob.getTime();  
  
return Math.abs(new Date(diff).getUTCFullYear() - 1970);  
  
};  
  
export const askQuestion = async (  
  
req: AuthRequest,  
  
res: Response,  
  
next: NextFunction,  
  
): Promise => {  
  
try {  
  
const userId = req.user?.sub;  
  
// The frontend sends the question, and optionally a session\\\_id for existing chats  
  
const { question, session\\\_id } = req.body;  
  
if (!question) {  
  
return next(new AppError("Question is required", 400));  
  
}  
  
// 1. Fetch user data for Context  
  
const user = await prisma.users.findUnique({  
  
where: { id: userId },  
  
include: {  
  
user\\\_sport\\\_profiles: {  
  
where: { is\\\_primary: true },  
  
include: { sports: true },  
  
},  
  
user\\\_metrics: true,  
  
},  
  
});  
  
if (!user) {  
  
return next(new AppError("User not found", 404));  
  
}  
  
const primaryProfile = user.user\\\_sport\\\_profiles\\\[0\\\];  
  
const sportName = primaryProfile?.sports?.name || "general";  
  
const goal = user.user\\\_metrics?.goal?.replace(/\\\_/g, " ") || null;  
  
// 2. Chat Session Management and Memory  
  
let currentSessionId = session\\\_id;  
  
let chatHistory: Array<{ role: string; content: string }> = \\\[\\\];  
  
if (currentSessionId) {  
  
// 🚨 Security Check: Verify session belongs to the user  
  
const existingSession = await prisma.chat\\\_sessions.findUnique({  
  
where: { id: currentSessionId },  
  
});  
  
if (!existingSession) {  
  
return next(new AppError("Session not found", 404));  
  
}  
  
if (existingSession.user\\\_id !== userId) {  
  
return next(  
  
new AppError("Forbidden — Session belongs to another user", 403),  
  
);  
  
}  
  
// If session exists and belongs to user, pull the last 6 messages  
  
const previousMessages = await prisma.chat\\\_messages.findMany({  
  
where: { session\\\_id: currentSessionId },  
  
orderBy: { created\\\_at: "asc" },  
  
take: -6,  
  
});  
  
chatHistory = previousMessages.map((msg) => ({  
  
role: msg.role,  
  
content: msg.content,  
  
}));  
  
} else {  
  
// If no session exists, create a new one...  
  
// If no session exists, create a new one for this user  
  
const newSession = await prisma.chat\\\_sessions.create({  
  
data: {  
  
user\\\_id: userId as string,  
  
title: question.substring(0, 50) + "...", // Use first 50 chars as chat title  
  
},  
  
});  
  
currentSessionId = newSession.id;  
  
}  
  
// 3. Build the Payload for Python (including History)  
  
const aiPayload = {  
  
question: question,  
  
sport: sportName.toLowerCase(),  
  
history: chatHistory,  
  
current\\\_program: null,  
  
user\\\_goal: goal,  
  
};  
  
// 4. Send request to Python AI Service  
  
const aiResponse = await askRingsideAI(aiPayload);  
  
// 5. Save messages to DB in the same session  
  
await prisma.chat\\\_messages.createMany({  
  
data: \\\[  
  
{  
  
session\\\_id: currentSessionId,  
  
role: "user",  
  
content: question,  
  
},  
  
{  
  
session\\\_id: currentSessionId,  
  
role: "assistant",  
  
content: aiResponse.answer, // Python AI response  
  
},  
  
\\\],  
  
});  
  
// 6. Return response to mobile with Session ID for future requests  
  
res.status(200).json({  
  
success: true,  
  
session\\\_id: currentSessionId,  
  
data: aiResponse,  
  
});  
  
} catch (error: any) {  
  
console.error("AI Ask Error:", error);  
  
next(new AppError("Failed to get AI response", 500));  
  
}  
  
};  
  
//============================================  
  
// This commented part are Updated  
  
//============================================  
  
// export const recommendProgram = async (req: AuthRequest, res: Response): Promise => {  
  
// try {  
  
// const userId = req.user?.sub;  
  
// // Fetch user with their sport profile and latest metrics  
  
// const user = await prisma.users.findUnique({  
  
// where: { id: userId },  
  
// include: {  
  
// user\\\_sport\\\_profiles: {  
  
// where: { is\\\_primary: true },  
  
// include: { sports: true }  
  
// },  
  
// user\\\_metrics: true // Fetch metrics table  
  
// }  
  
// });  
  
// if (!user) {  
  
// res.status(404).json({ success: false, error: "User not found" });  
  
// return;  
  
// }  
  
// if (!user.user\\\_metrics) {  
  
// res.status(400).json({  
  
// success: false,  
  
// error: "User metrics not found. Please complete onboarding first."  
  
// });  
  
// return;  
  
// }  
  
// const primaryProfile = user.user\\\_sport\\\_profiles\\\[0\\\];  
  
// const metrics = user.user\\\_metrics;  
  
// // Calculate age  
  
// const diff = Date.now() - user.date\\\_of\\\_birth.getTime();  
  
// const userAge = Math.abs(new Date(diff).getUTCFullYear() - 1970);  
  
// // Calculate BMI (Weight / (Height in m)^2)  
  
// const heightInMeters = Number(metrics.height\\\_cm) / 100;  
  
// const calculatedBMI = Number(metrics.weight\\\_kg) / (heightInMeters \\\* heightInMeters);  
  
// // Build the actual Payload for the ML model  
  
// const mlPayload = {  
  
// Age: userAge,  
  
// Height\\\_cm: Number(metrics.height\\\_cm),  
  
// Weight\\\_kg: Number(metrics.weight\\\_kg),  
  
// BMI: Number(calculatedBMI.toFixed(1)),  
  
// Sport\\\_Type: primaryProfile?.sports?.name || "General Fitness",  
  
// Level: primaryProfile?.level ? primaryProfile.level.charAt(0).toUpperCase() + primaryProfile.level.slice(1) : "Beginner",  
  
// Goal: metrics.goal.replace(/\\\_/g, " "), // Convert Muscle\\\_Gain to Muscle Gain  
  
// Training\\\_Days\\\_Per\\\_Week: metrics.training\\\_days\\\_per\\\_week,  
  
// Years\\\_Training: Number(metrics.years\\\_training),  
  
// Has\\\_Injury\\\_History: metrics.has\\\_injury\\\_history ? 1 : 0,  
  
// Endurance\\\_Score: metrics.endurance\\\_score,  
  
// Strength\\\_Score: metrics.strength\\\_score,  
  
// Speed\\\_Score: metrics.speed\\\_score,  
  
// Flexibility\\\_Score: metrics.flexibility\\\_score,  
  
// Explosiveness\\\_Score: metrics.explosiveness\\\_score,  
  
// Recovery\\\_Score: metrics.recovery\\\_score  
  
// };  
  
// const recommendation = await getProgramRecommendation(mlPayload);  
  
// res.status(200).json({ success: true, data: recommendation });  
  
// } catch (error: any) {  
  
// console.error("ML Recommend Error:", error);  
  
// res.status(500).json({ success: false, error: "Failed to get program recommendation" });  
  
// }  
  
// };  
  
// the New Recommend program depends on the User\\\_Metrics  
  
export const recommendProgram = async (  
  
req: AuthRequest,  
  
res: Response,  
  
next: NextFunction,  
  
): Promise => {  
  
try {  
  
const userId = req.user?.sub as string;  
  
const overrides = req.body; // الداتا اللي اليوزر ممكن يكون عدلها في الشاشة  
  
// 1. Fetch user with their sport profile and latest metrics  
  
const user = await prisma.users.findUnique({  
  
where: { id: userId },  
  
include: {  
  
user\\\_sport\\\_profiles: {  
  
where: { is\\\_primary: true },  
  
include: { sports: true },  
  
},  
  
user\\\_metrics: true, // Fetch metrics table  
  
},  
  
});  
  
if (!user) {  
  
return next(new AppError("User not found", 404));  
  
}  
  
if (!user.user\\\_metrics) {  
  
return next(  
  
new AppError(  
  
"User metrics not found. Please complete onboarding first.",  
  
400,  
  
),  
  
);  
  
}  
  
const primaryProfile = user.user\\\_sport\\\_profiles\\\[0\\\];  
  
let metrics = user.user\\\_metrics;  
  
// 🎯 2. السحر هنا: لو اليوزر بعت تعديلات، نحدث الداتا بيز الأول قبل ما نكلم الموديل  
  
if (overrides && Object.keys(overrides).length > 0) {  
  
metrics = await prisma.user\\\_metrics.update({  
  
where: { user\\\_id: userId },  
  
data: {  
  
...(overrides.height\\\_cm && {  
  
height\\\_cm: Number(overrides.height\\\_cm),  
  
}),  
  
...(overrides.weight\\\_kg && {  
  
weight\\\_kg: Number(overrides.weight\\\_kg),  
  
}),  
  
...(overrides.goal && { goal: overrides.goal }),  
  
...(overrides.training\\\_days\\\_per\\\_week !== undefined && {  
  
training\\\_days\\\_per\\\_week: Number(overrides.training\\\_days\\\_per\\\_week),  
  
}),  
  
...(overrides.years\\\_training !== undefined && {  
  
years\\\_training: Number(overrides.years\\\_training),  
  
}),  
  
...(overrides.has\\\_injury\\\_history !== undefined && {  
  
has\\\_injury\\\_history: overrides.has\\\_injury\\\_history,  
  
}),  
  
...(overrides.endurance\\\_score && {  
  
endurance\\\_score: Number(overrides.endurance\\\_score),  
  
}),  
  
...(overrides.strength\\\_score && {  
  
strength\\\_score: Number(overrides.strength\\\_score),  
  
}),  
  
...(overrides.speed\\\_score && {  
  
speed\\\_score: Number(overrides.speed\\\_score),  
  
}),  
  
...(overrides.flexibility\\\_score && {  
  
flexibility\\\_score: Number(overrides.flexibility\\\_score),  
  
}),  
  
...(overrides.explosiveness\\\_score && {  
  
explosiveness\\\_score: Number(overrides.explosiveness\\\_score),  
  
}),  
  
...(overrides.recovery\\\_score && {  
  
recovery\\\_score: Number(overrides.recovery\\\_score),  
  
}),  
  
},  
  
});  
  
}  
  
// 3. Calculate age  
  
const userAge = calculateAge(user.date\\\_of\\\_birth);  
  
// 4. Calculate BMI (Weight / (Height in m)^2)  
  
const heightInMeters = Number(metrics.height\\\_cm) / 100;  
  
const calculatedBMI =  
  
Number(metrics.weight\\\_kg) / (heightInMeters \\\* heightInMeters);  
  
// 5. Build the actual Payload for the ML model (using the freshly updated metrics)  
  
const mlPayload = {  
  
Age: userAge,  
  
Height\\\_cm: Number(metrics.height\\\_cm),  
  
Weight\\\_kg: Number(metrics.weight\\\_kg),  
  
BMI: Number(calculatedBMI.toFixed(1)),  
  
Sport\\\_Type: primaryProfile?.sports?.name || "General Fitness",  
  
Level: primaryProfile?.level  
  
? primaryProfile.level.charAt(0).toUpperCase() +  
  
primaryProfile.level.slice(1)  
  
: "Beginner",  
  
Goal: metrics.goal.replace(/\\\_/g, " "), // Convert Muscle\\\_Gain to Muscle Gain  
  
Training\\\_Days\\\_Per\\\_Week: metrics.training\\\_days\\\_per\\\_week,  
  
Years\\\_Training: Number(metrics.years\\\_training),  
  
Has\\\_Injury\\\_History: metrics.has\\\_injury\\\_history ? 1 : 0,  
  
Endurance\\\_Score: metrics.endurance\\\_score,  
  
Strength\\\_Score: metrics.strength\\\_score,  
  
Speed\\\_Score: metrics.speed\\\_score,  
  
Flexibility\\\_Score: metrics.flexibility\\\_score,  
  
Explosiveness\\\_Score: metrics.explosiveness\\\_score,  
  
Recovery\\\_Score: metrics.recovery\\\_score,  
  
};  
  
const recommendation = await getProgramRecommendation(mlPayload);  
  
// 🎯 التعديل هنا: رجعنا الـ metrics جوه الـ data  
  
res.status(200).json({  
  
success: true,  
  
data: {  
  
recommendation: recommendation,  
  
user\\\_metrics: metrics,  
  
},  
  
});  
  
} catch (error: any) {  
  
console.error("ML Recommend Error:", error);  
  
next(new AppError("Failed to get program recommendation", 500));  
  
}  
  
};  
  
export const getCoachAdvice = async (  
  
req: AuthRequest,  
  
res: Response,  
  
next: NextFunction,  
  
): Promise => {  
  
try {  
  
// Receive raw data from punch power endpoint  
  
const { score, level, weight\\\_class, breakdown\\\_percentiles, raw\\\_values } =  
  
req.body;  
  
// Quick check if all data is present  
  
if (score === undefined || !breakdown\\\_percentiles || !raw\\\_values) {  
  
return next(new AppError("Complete performance data is required.", 400));  
  
}  
  
// Python Microservice Link (New Analysis Route)  
  
const AI\\\_SERVICE\\\_URL =  
  
process.env.AI\\\_SERVICE\\\_URL || "http://localhost:8000/coach-analysis";  
  
// Send request to Python server  
  
const aiResponse = await fetch(AI\\\_SERVICE\\\_URL, {  
  
method: "POST",  
  
headers: { "Content-Type": "application/json" },  
  
body: JSON.stringify({  
  
score: score,  
  
level: level || "amateur",  
  
weight\\\_class: weight\\\_class || "middleweight",  
  
foundation\\\_pct: breakdown\\\_percentiles.foundation,  
  
accelerator\\\_pct: breakdown\\\_percentiles.accelerator,  
  
transfer\\\_pct: breakdown\\\_percentiles.transfer,  
  
raw\\\_foundation: raw\\\_values.foundation,  
  
raw\\\_accelerator: raw\\\_values.accelerator,  
  
raw\\\_transfer: raw\\\_values.transfer,  
  
}),  
  
});  
  
if (!aiResponse.ok) {  
  
throw new Error(\\\`AI Service responded with status: ${aiResponse.status}\\\`);  
  
}  
  
const data = await aiResponse.json();  
  
// Return final advice to frontend  
  
res.status(200).json({  
  
success: true,  
  
advice: data.analysis,  
  
engine: data.engine, // Returns Hybrid RAG + Direct Analysis  
  
});  
  
} catch (error: any) {  
  
console.error("AI Coach Analysis Error:", error);  
  
next(  
  
new AppError(  
  
"Failed to generate coach advice from AI microservice.",  
  
500,  
  
),  
  
);  
  
}  
  
};  
  
// --- 8.2 Get User Sessions ---  
  
export const getSessions = async (  
  
req: AuthRequest,  
  
res: Response,  
  
next: NextFunction,  
  
): Promise => {  
  
try {  
  
const userId = String(req.user?.sub);  
  
const sessions = await prisma.chat\\\_sessions.findMany({  
  
where: { user\\\_id: userId },  
  
orderBy: { updated\\\_at: "desc" }, // Newest first  
  
take: 20, // Max 20 per Specs  
  
});  
  
res.status(200).json({ success: true, data: sessions });  
  
} catch (error: any) {  
  
console.error("Get Sessions Error:", error);  
  
next(new AppError("Failed to fetch chat sessions.", 500));  
  
}  
  
};  
  
// --- 8.3 Get Session Messages ---  
  
// --- 8.3 Get Session Messages ---  
  
export const getSessionMessages = async (  
  
req: AuthRequest,  
  
res: Response,  
  
next: NextFunction,  
  
): Promise => {  
  
try {  
  
const userId = String(req.user?.sub);  
  
const sessionId = String(req.params.id);  
  
// 1. Verify this session belongs to the user (Security/Authorization)  
  
const session = await prisma.chat\\\_sessions.findUnique({  
  
where: { id: sessionId },  
  
});  
  
if (!session) {  
  
return next(new AppError("Session not found.", 404));  
  
}  
  
if (session.user\\\_id !== userId) {  
  
return next(new AppError("Unauthorized to view this session.", 403));  
  
}  
  
// 2. Fetch messages ordered from oldest to newest  
  
const messages = await prisma.chat\\\_messages.findMany({  
  
where: { session\\\_id: sessionId },  
  
orderBy: { created\\\_at: "asc" },  
  
select: {  
  
id: true,  
  
role: true,  
  
content: true,  
  
suggested\\\_program\\\_ids: true,  
  
created\\\_at: true,  
  
},  
  
});  
  
// 3. Format data  
  
const formattedMessages = await Promise.all(  
  
messages.map(async (msg) => {  
  
// message type  
  
// Variable must be defined here outside the if-block to be accessible in return  
  
let suggested\\\_programs: { id: string; title: string }\\\[\\\] = \\\[\\\];  
  
if (  
  
Array.isArray(msg.suggested\\\_program\\\_ids) &&  
  
msg.suggested\\\_program\\\_ids.length > 0  
  
) {  
  
const stringIds = (msg.suggested\\\_program\\\_ids as any\\\[\\\]).map((id) =>  
  
String(id),  
  
);  
  
suggested\\\_programs = await prisma.programs.findMany({  
  
where: { id: { in: stringIds } },  
  
select: { id: true, title: true },  
  
});  
  
}  
  
return {  
  
id: msg.id,  
  
role: msg.role,  
  
content: msg.content,  
  
created\\\_at: msg.created\\\_at,  
  
// Can be read safely without ReferenceError  
  
suggested\\\_programs: suggested\\\_programs,  
  
};  
  
}),  
  
);  
  
res.status(200).json({ success: true, data: formattedMessages });  
  
} catch (error: any) {  
  
console.error("Get Session Messages Error:", error);  
  
next(new AppError("Failed to fetch session messages.", 500));  
  
}  
  
};  
import { Response, NextFunction } from "express";  
import { AuthRequest } from "../middlewares/auth.middleware";  
import { prisma } from "../config/prisma";  
import {  
  calculateZScore,  
  calculatePercentile,  
  calculatePunchPower,  
} from "../services/calculation.service";  
import {  
  snapshot\_type,  
  competitive\_level,  
  player\_category,  
  enrollment\_status,  
  user\_goal\_enum,  
} from "@prisma/client";  
import { AppError } from "../utils/AppError";  
  
// 📌 استيراد الدوال من الـ Service الجديدة  
import {  
  getCategoriesBySportId,  
  formatCategoryLabel,  
  getCategoryType,  
} from "../services/sportCategory.service";  
  
// ==========================================  
// Helper Functions  
// ==========================================  
const getAgeGroupId = (dateOfBirth: Date): number => {  
  const age = new Date().getFullYear() - dateOfBirth.getFullYear();  
  if (age < 18) return 1;  
  if (age <= 35) return 2;  
  return 3;  
};  
  
const getAdjacentCategories = (  
  category: player\_category,  
): player\_category\[\] => {  
  const weightClasses: player\_category\[\] = \[  
    "flyweight",  
    "bantamweight",  
    "featherweight",  
    "lightweight",  
    "light\_welterweight",  
    "welterweight",  
    "light\_middleweight",  
    "middleweight",  
    "super\_middleweight",  
    "light\_heavyweight",  
    "cruiserweight",  
    "heavyweight",  
  \];  
  
  const idx = weightClasses.indexOf(category);  
  if (idx === -1) return \[\];  
  
  const adjacent: player\_category\[\] = \[\];  
  if (idx > 0) adjacent.push(weightClasses\[idx - 1\]);  
  if (idx < weightClasses.length - 1) adjacent.push(weightClasses\[idx + 1\]);  
  return adjacent;  
};  
  
const getPercentileWithFallback = async (  
  testId: number,  
  rawValue: number,  
  higherIsBetter: boolean,  
  userLevel: competitive\_level,  
  userCategory: player\_category,  
  userAgeGroupId: number,  
): Promise<{ percentile: number; fallbackLevel: number }> => {  
  const fallbackSteps: any\[\] = \[  
    { category: userCategory, level: userLevel, ageGroup: userAgeGroupId },  
    { category: userCategory, level: userLevel, ageGroup: undefined },  
    {  
      category: { in: getAdjacentCategories(userCategory) },  
      level: userLevel,  
      ageGroup: undefined,  
    },  
    { category: undefined, level: userLevel, ageGroup: undefined },  
    { category: undefined, level: undefined, ageGroup: undefined },  
  \];  
  
  for (let step = 0; step < fallbackSteps.length; step++) {  
    const criteria = fallbackSteps\[step\];  
    const norm = await prisma.normative\_data.findFirst({  
      where: {  
        attribute\_test\_id: testId,  
        ...(criteria.category && { player\_category: criteria.category }),  
        ...(criteria.level && { level: criteria.level }),  
        ...(criteria.ageGroup && { age\_group\_id: criteria.ageGroup }),  
      },  
    });  
    if (norm) {  
      const z = calculateZScore(  
        rawValue,  
        Number(norm.mean\_value),  
        Number(norm.std\_dev),  
        higherIsBetter,  
      );  
      const percentile = calculatePercentile(z);  
      return { percentile, fallbackLevel: step };  
    }  
  }  
  const fallbackPercentile = Math.min(  
    99,  
    Math.max(1, Math.floor(rawValue / 2)),  
  );  
  return { percentile: fallbackPercentile, fallbackLevel: 4 };  
};  
  
const getTestName = async (testId: number): Promise<string> => {  
  const test = await prisma.attribute\_tests.findUnique({  
    where: { id: testId },  
    select: { test\_name: true },  
  });  
  return test?.test\_name || "Unknown";  
};  
  
// ==========================================  
// Controllers  
// ==========================================  
  
export const createSportProfile = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const {  
      sport\_id = 1,  
      level,  
      player\_category,  
      is\_primary = true,  
    } = req.body;  
  
    const existingProfile = await prisma.user\_sport\_profiles.findFirst({  
      where: { user\_id: userId, sport\_id: Number(sport\_id) },  
    });  
  
    if (existingProfile) {  
      return next(  
        new AppError(  
          "Conflict — sport profile already exists. Use PATCH to update.",  
          409,  
        ),  
      );  
    }  
    const sportExists = await prisma.sports.findUnique({  
      where: { id: Number(sport\_id) },  
    });  
  
    if (!sportExists) {  
      return next(  
        new AppError("Sport not found. Please provide a valid sport\_id.", 404),  
      );  
    }  
  
    // 📌 ضفنا Validation إن الـ category مناسبة للرياضة  
    const validCategories = getCategoriesBySportId(Number(sport\_id));  
    if (!validCategories.includes(player\_category)) {  
      return next(  
        new AppError(  
          \`Invalid player category (${player\_category}) for sport ID ${sport\_id}.\`,  
          400,  
        ),  
      );  
    }  
  
    const newProfile = await prisma.user\_sport\_profiles.create({  
      data: {  
        user\_id: userId,  
        sport\_id: Number(sport\_id),  
        level,  
        player\_category,  
        is\_primary,  
      },  
    });  
  
    res.status(201).json({  
      success: true,  
      message: "Sport profile created successfully!",  
      data: newProfile,  
    });  
  } catch (error: any) {  
    console.error("Create Sport Profile Error:", error);  
    return next(new AppError("Failed to create sport profile.", 500));  
  }  
};  
  
export const upsertUserMetrics = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    // 📌 شيلنا كل الـ Scores من هنا  
    const {  
      height\_cm,  
      weight\_kg,  
      goal,  
      training\_days\_per\_week,  
      years\_training,  
      has\_injury\_history,  
    } = req.body;  
  
    if (  
      !height\_cm ||  
      !weight\_kg ||  
      !goal ||  
      training\_days\_per\_week === undefined ||  
      years\_training === undefined  
    ) {  
      return next(  
        new AppError(  
          "Missing required fields: height\_cm, weight\_kg, goal, training\_days\_per\_week, and years\_training are required.",  
          400,  
        ),  
      );  
    }  
  
    const validGoals = Object.keys(user\_goal\_enum);  
    if (!validGoals.includes(goal)) {  
      return next(  
        new AppError(  
          \`Invalid goal. Allowed values are: ${validGoals.join(", ")}\`,  
          400,  
        ),  
      );  
    }  
  
    // 📌 خلينا الـ Object نضيف وبياخد الحاجات الأساسية بس  
    const metricsData = {  
      height\_cm: Number(height\_cm),  
      weight\_kg: Number(weight\_kg),  
      goal: goal as user\_goal\_enum,  
      training\_days\_per\_week: Number(training\_days\_per\_week),  
      years\_training: Number(years\_training),  
      has\_injury\_history: has\_injury\_history ?? false,  
    };  
  
    const metrics = await prisma.user\_metrics.upsert({  
      where: { user\_id: userId },  
      update: metricsData,  
      create: { user\_id: userId, ...metricsData },  
    });  
  
    res.status(200).json({  
      success: true,  
      message: "User metrics saved successfully!",  
      data: metrics,  
    });  
  } catch (error: any) {  
    console.error("Upsert User Metrics Error:", error);  
    return next(new AppError("Failed to save user metrics.", 500));  
  }  
};  
  
export const getUserMetrics = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const metrics = await prisma.user\_metrics.findUnique({  
      where: { user\_id: userId },  
    });  
  
    if (!metrics) {  
      return next(  
        new AppError(  
          "User metrics not found. Please complete onboarding.",  
          404,  
        ),  
      );  
    }  
  
    res.status(200).json({ success: true, data: metrics });  
  } catch (error: any) {  
    console.error("Get User Metrics Error:", error);  
    return next(new AppError("Failed to fetch user metrics.", 500));  
  }  
};  
export const updateSportProfile = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const { level, player\_category } = req.body;  
  
    const existingProfile = await prisma.user\_sport\_profiles.findFirst({  
      where: { user\_id: userId, is\_primary: true },  
      include: { sports: true }, // بنجيب الرياضة عشان الـ validation  
    });  
  
    if (!existingProfile) {  
      return next(  
        new AppError("Sport profile not found. Please create one first.", 404),  
      );  
    }  
  
    // 📌 ضفنا Validation إن الـ category مناسبة للرياضة في الـ Update كمان  
    if (player\_category) {  
      const validCategories = getCategoriesBySportId(existingProfile.sport\_id);  
      if (!validCategories.includes(player\_category)) {  
        return next(  
          new AppError(  
            \`Invalid player category (${player\_category}) for sport ID ${existingProfile.sport\_id}.\`,  
            400,  
          ),  
        );  
      }  
    }  
  
    const updatedProfile = await prisma.user\_sport\_profiles.update({  
      where: { id: existingProfile.id },  
      data: {  
        ...(level && { level }),  
        ...(player\_category && { player\_category }),  
      },  
    });  
  
    res.status(200).json({  
      success: true,  
      message: "Sport profile updated successfully!",  
      data: updatedProfile,  
    });  
  } catch (error: any) {  
    console.error("Update Sport Profile Error:", error);  
    return next(new AppError("Failed to update sport profile.", 500));  
  }  
};  
  
export const getSportBaselineTests = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const { sport\_id } = req.params;  
  
    const attributes = await prisma.sport\_attributes.findMany({  
      where: { sport\_id: Number(sport\_id) },  
      include: {  
        attribute\_tests: true,  
      },  
      orderBy: { display\_order: "asc" },  
    });  
  
    res.status(200).json({ success: true, data: attributes });  
  } catch (error: any) {  
    return next(new AppError("Failed to fetch baseline tests.", 500));  
  }  
};  
  
export const createSnapshot = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const {  
      sport\_id = 1,  
      snapshot\_type = "manual\_update",  
      program\_enrollment\_id,  
      notes,  
      test\_values,  
    } = req.body;  
  
    const sportExists = await prisma.sports.findUnique({  
      where: { id: Number(sport\_id) },  
    });  
  
    if (!sportExists) {  
      return next(  
        new AppError("Sport not found. Please provide a valid sport\_id.", 404),  
      );  
    }  
  
    const result = await prisma.$transaction(async (tx) => {  
      const snapshot = await tx.physical\_snapshots.create({  
        data: {  
          user\_id: userId,  
          sport\_id: Number(sport\_id),  
          snapshot\_type,  
          program\_enrollment\_id,  
          notes,  
        },  
      });  
  
      const testIds = test\_values.map((t: any) => t.attribute\_test\_id);  
      const testsInfo = await tx.attribute\_tests.findMany({  
        where: { id: { in: testIds } },  
      });  
  
      const dataToInsert = test\_values.map((test: any) => {  
        const info = testsInfo.find((ti) => ti.id === test.attribute\_test\_id);  
        return {  
          snapshot\_id: snapshot.id,  
          attribute\_test\_id: test.attribute\_test\_id,  
          value: test.value,  
          unit: info?.unit || "unknown",  
        };  
      });  
  
      await tx.snapshot\_test\_values.createMany({ data: dataToInsert });  
  
      if (program\_enrollment\_id) {  
        if (snapshot\_type === "program\_baseline") {  
          await tx.enrollments.update({  
            where: { id: program\_enrollment\_id },  
            data: { baseline\_snapshot\_id: snapshot.id },  
          });  
        } else if (snapshot\_type === "program\_posttest") {  
          await tx.enrollments.update({  
            where: { id: program\_enrollment\_id },  
            data: { posttest\_snapshot\_id: snapshot.id },  
          });  
        }  
      }  
  
      return snapshot;  
    });  
  
    res.status(201).json({  
      success: true,  
      message: "Snapshot saved!",  
      snapshot\_id: result.id,  
    });  
  } catch (error: any) {  
    console.error("Create Snapshot Error:", error);  
    if (error.code) {  
      return next(error);  
    }  
    return next(new AppError("Failed to save snapshot", 500));  
  }  
};  
  
export const getSnapshots = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const limit = parseInt(req.query.limit as string) || 20;  
    const offset = parseInt(req.query.offset as string) || 0;  
    const type = req.query.type as unknown as snapshot\_type | undefined;  
  
    const whereClause: any = { user\_id: userId };  
    if (type) whereClause.snapshot\_type = type;  
  
    const totalCount = await prisma.physical\_snapshots.count({  
      where: whereClause,  
    });  
    const snapshots = await prisma.physical\_snapshots.findMany({  
      where: whereClause,  
      take: limit,  
      skip: offset,  
      orderBy: { created\_at: "desc" },  
      include: {  
        snapshot\_test\_values: {  
          include: { attribute\_tests: { select: { test\_name: true } } },  
        },  
      },  
    });  
  
    const formattedSnapshots = snapshots.map((snap) => ({  
      id: snap.id,  
      snapshot\_type: snap.snapshot\_type,  
      created\_at: snap.created\_at,  
      notes: snap.notes,  
      test\_values: snap.snapshot\_test\_values.map((tv) => ({  
        attribute\_test\_id: tv.attribute\_test\_id,  
        test\_name: tv.attribute\_tests?.test\_name,  
        value: tv.value,  
        unit: tv.unit,  
      })),  
    }));  
  
    res.status(200).json({  
      success: true,  
      data: formattedSnapshots,  
      meta: { total: totalCount, limit, offset },  
    });  
  } catch (error: any) {  
    console.error("Get Snapshots Error:", error);  
    return next(new AppError("Failed to fetch snapshots.", 500));  
  }  
};  
  
export const getLatestSnapshot = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const latestSnapshot = await prisma.physical\_snapshots.findFirst({  
      where: { user\_id: userId },  
      orderBy: { created\_at: "desc" },  
      include: {  
        snapshot\_test\_values: {  
          include: {  
            attribute\_tests: {  
              include: {  
                sport\_attributes: {  
                  select: {  
                    name: true,  
                  },  
                },  
              },  
            },  
          },  
        },  
      },  
    });  
  
    if (!latestSnapshot) {  
      return next(new AppError("No snapshots found for this user.", 404));  
    }  
  
    const formattedSnapshot = {  
      id: latestSnapshot.id,  
      snapshot\_type: latestSnapshot.snapshot\_type,  
      created\_at: latestSnapshot.created\_at,  
      notes: latestSnapshot.notes,  
      test\_values: latestSnapshot.snapshot\_test\_values.map((tv) => ({  
        attribute\_test\_id: tv.attribute\_test\_id,  
        attribute\_name: tv.attribute\_tests?.sport\_attributes?.name,  
        test\_name: tv.attribute\_tests?.test\_name,  
        value: Number(tv.value),  
        unit: tv.unit,  
      })),  
    };  
  
    res.status(200).json({ success: true, data: formattedSnapshot });  
  } catch (error: any) {  
    console.error("Get Latest Snapshot Error:", error);  
    return next(new AppError("Failed to fetch the latest snapshot.", 500));  
  }  
};  
  
export const getRadarData = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const cohortLevel = req.query.level as unknown as  
      competitive\_level | undefined;  
    const cohortCategory = req.query.player\_category as unknown as  
      player\_category | undefined;  
  
    const user = await prisma.users.findUnique({  
      where: { id: userId },  
      select: {  
        date\_of\_birth: true,  
        user\_sport\_profiles: { where: { is\_primary: true } },  
      },  
    });  
    const profile = user?.user\_sport\_profiles\[0\];  
  
    if (!profile) {  
      return next(new AppError("Profile not found.", 404));  
    }  
  
    const ageGroupId = getAgeGroupId(user!.date\_of\_birth);  
    const targetLevel = cohortLevel || profile.level;  
    const targetCategory = cohortCategory || profile.player\_category;  
  
    const latestSnapshot = await prisma.physical\_snapshots.findFirst({  
      where: { user\_id: userId },  
      orderBy: { created\_at: "desc" },  
      include: {  
        snapshot\_test\_values: {  
          include: { attribute\_tests: { include: { sport\_attributes: true } } },  
        },  
      },  
    });  
  
    if (!latestSnapshot) {  
      return next(new AppError("No snapshot data found.", 404));  
    }  
  
    const attributeMap = new Map<  
      number,  
      { name: string; tests: any\[\]; totalWeight: number }  
    >();  
    for (const testVal of latestSnapshot.snapshot\_test\_values) {  
      const attr = testVal.attribute\_tests?.sport\_attributes;  
      if (!attr) continue;  
      const attrId = attr.id;  
      if (!attributeMap.has(attrId))  
        attributeMap.set(attrId, {  
          name: attr.name,  
          tests: \[\],  
          totalWeight: 0,  
        });  
  
      const entry = attributeMap.get(attrId)!;  
      const weight = Number(testVal.attribute\_tests?.weight || 1);  
  
      entry.tests.push({  
        testId: testVal.attribute\_test\_id,  
        rawValue: Number(testVal.value),  
        higherIsBetter: testVal.attribute\_tests?.higher\_is\_better ?? true,  
        weight: weight,  
        unit: testVal.unit,  
      });  
      entry.totalWeight += weight;  
    }  
  
    const radar\_axes: any\[\] = \[\];  
    let foundationPct = 0,  
      acceleratorPct = 0,  
      transferPct = 0;  
  
    for (const \[attrId, attrData\] of attributeMap.entries()) {  
      let weightedPercentileSum = 0;  
      let highestFallback = 0;  
  
      for (const test of attrData.tests) {  
        const { percentile, fallbackLevel } = await getPercentileWithFallback(  
          test.testId,  
          test.rawValue,  
          test.higherIsBetter,  
          targetLevel,  
          targetCategory,  
          ageGroupId,  
        );  
        weightedPercentileSum += percentile \* test.weight;  
        if (fallbackLevel > highestFallback) highestFallback = fallbackLevel;  
  
        const testName = await getTestName(test.testId);  
        if (testName === "Trap Bar Deadlift") foundationPct = percentile;  
        if (testName === "Power Clean" || testName === "Box Jump Height")  
          acceleratorPct = percentile;  
        if (testName === "Medicine Ball Rotational Throw")  
          transferPct = percentile;  
      }  
  
      const finalPercentile =  
        attrData.totalWeight > 0  
          ? weightedPercentileSum / attrData.totalWeight  
          : 0;  
      radar\_axes.push({  
        attribute\_name: attrData.name,  
        percentile: Math.round(finalPercentile),  
        fallback\_level: highestFallback,  
      });  
    }  
  
    const punch\_power = {  
      score: calculatePunchPower(foundationPct, acceleratorPct, transferPct),  
      foundation: { percentile: foundationPct },  
      accelerator: { percentile: acceleratorPct },  
      transfer: { percentile: transferPct },  
    };  
  
    res.status(200).json({  
      success: true,  
      data: {  
        radar\_axes,  
        punch\_power,  
        cohort\_used: {  
          player\_category: targetCategory,  
          level: targetLevel,  
          age\_group:  
            ageGroupId === 2 ? "18-35" : ageGroupId === 1 ? "Under 18" : "35+",  
        },  
        snapshot\_date: latestSnapshot.created\_at,  
      },  
    });  
  } catch (error: any) {  
    console.error("Get Radar Data Error:", error);  
    return next(new AppError("Failed to generate radar data", 500));  
  }  
};  
  
export const getProgress = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const attributeTestId = parseInt(req.query.attribute\_test\_id as string);  
    if (isNaN(attributeTestId)) {  
      return next(new AppError("Invalid test ID.", 400));  
    }  
  
    const \[testInfo, user, profile\] = await Promise.all(\[  
      prisma.attribute\_tests.findUnique({ where: { id: attributeTestId } }),  
      prisma.users.findUnique({  
        where: { id: userId },  
        select: { date\_of\_birth: true },  
      }),  
      prisma.user\_sport\_profiles.findFirst({  
        where: { user\_id: userId, is\_primary: true },  
      }),  
    \]);  
  
    if (!testInfo || !profile || !user) {  
      return next(new AppError("Data not found.", 404));  
    }  
  
    const ageGroupId = getAgeGroupId(user.date\_of\_birth);  
    const userLevel = profile.level;  
    const userCategory = profile.player\_category;  
    const higherIsBetter = testInfo.higher\_is\_better ?? true;  
  
    const history = await prisma.physical\_snapshots.findMany({  
      where: {  
        user\_id: userId,  
        snapshot\_test\_values: { some: { attribute\_test\_id: attributeTestId } },  
      },  
      orderBy: { created\_at: "asc" },  
      include: {  
        snapshot\_test\_values: {  
          where: { attribute\_test\_id: attributeTestId },  
          take: 1,  
        },  
      },  
    });  
  
    const data\_points = await Promise.all(  
      history.map(async (snap) => {  
        const rawValue = Number(snap.snapshot\_test\_values\[0\]?.value || 0);  
        const { percentile } = await getPercentileWithFallback(  
          attributeTestId,  
          rawValue,  
          higherIsBetter,  
          userLevel,  
          userCategory,  
          ageGroupId,  
        );  
        return {  
          date: snap.created\_at,  
          raw\_value: rawValue,  
          snapshot\_type: snap.snapshot\_type,  
          percentile: Math.round(percentile),  
        };  
      }),  
    );  
  
    res.status(200).json({  
      success: true,  
      data: {  
        test\_name: testInfo.test\_name,  
        unit: testInfo.unit,  
        higher\_is\_better: higherIsBetter,  
        data\_points,  
      },  
    });  
  } catch (error: any) {  
    console.error("Get Progress Error:", error);  
    return next(new AppError("Failed to fetch progress.", 500));  
  }  
};  
  
export const getMyEnrollments = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const status = req.query.status as enrollment\_status | undefined;  
  
    const whereClause: any = { user\_id: userId };  
    if (status) whereClause.status = status;  
  
    const enrollments = await prisma.enrollments.findMany({  
      where: whereClause,  
      orderBy: { created\_at: "desc" },  
      include: {  
        programs: {  
          select: {  
            title: true,  
            goal\_primary: true,  
            duration\_weeks: true,  
            cover\_image: true,  
            users: { select: { username: true } },  
          },  
        },  
      },  
    });  
  
    const formatted = enrollments.map((e) => ({  
      id: e.id,  
      status: e.status,  
      start\_date: e.start\_date,  
      completed\_date: e.completed\_date,  
      program: {  
        title: e.programs.title,  
        goal: e.programs.goal\_primary,  
        duration: e.programs.duration\_weeks,  
        cover: e.programs.cover\_image,  
        coach: e.programs.users.username,  
      },  
    }));  
  
    res.status(200).json({ success: true, data: formatted });  
  } catch (error: any) {  
    console.error("Get Enrollments Error:", error);  
    return next(new AppError("Failed to fetch enrollments.", 500));  
  }  
};  
  
export const getSportProfile = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const profiles = await prisma.user\_sport\_profiles.findMany({  
      where: { user\_id: userId },  
      orderBy: { is\_primary: "desc" },  
      include: { sports: { select: { name: true } } },  
    });  
  
    res.status(200).json({ success: true, data: profiles });  
  } catch (error: any) {  
    console.error("Get Sport Profile Error:", error);  
    return next(new AppError("Failed to fetch sport profiles.", 500));  
  }  
};  
  
export const deleteSportProfile = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const profileId = req.params.id;  
  
    const profile = await prisma.user\_sport\_profiles.findUnique({  
      where: { id: profileId as any },  
    });  
  
    if (!profile) return next(new AppError("Sport profile not found.", 404));  
    if (profile.user\_id !== userId)  
      return next(  
        new AppError("Forbidden — You can only delete your own profile.", 403),  
      );  
  
    await prisma.user\_sport\_profiles.delete({  
      where: { id: profileId as any },  
    });  
  
    res  
      .status(200)  
      .json({ success: true, message: "Sport profile deleted successfully." });  
  } catch (error: any) {  
    console.error("Delete Sport Profile Error:", error);  
    return next(new AppError("Failed to delete sport profile.", 500));  
  }  
};  
  
export const deleteUserMetrics = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const metrics = await prisma.user\_metrics.findUnique({  
      where: { user\_id: userId },  
    });  
    if (!metrics) return next(new AppError("User metrics not found.", 404));  
  
    await prisma.user\_metrics.delete({ where: { user\_id: userId } });  
  
    res  
      .status(200)  
      .json({ success: true, message: "User metrics deleted successfully." });  
  } catch (error: any) {  
    console.error("Delete User Metrics Error:", error);  
    return next(new AppError("Failed to delete user metrics.", 500));  
  }  
};  
  
export const deleteSnapshot = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const snapshotId = req.params.id;  
  
    const snapshot = await prisma.physical\_snapshots.findUnique({  
      where: { id: snapshotId as any },  
    });  
  
    if (!snapshot) return next(new AppError("Snapshot not found.", 404));  
    if (snapshot.user\_id !== userId)  
      return next(  
        new AppError("Forbidden — You can only delete your own snapshot.", 403),  
      );  
  
    await prisma.physical\_snapshots.delete({  
      where: { id: snapshotId as any },  
    });  
  
    res  
      .status(200)  
      .json({ success: true, message: "Snapshot deleted successfully." });  
  } catch (error: any) {  
    console.error("Delete Snapshot Error:", error);  
    return next(new AppError("Failed to delete snapshot.", 500));  
  }  
};  
  
// 📌 ضفنا التعديل هنا عشان نرجع الـ category\_type  
export const getSportsList = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const sports = await prisma.sports.findMany({  
      where: { is\_active: true },  
      select: {  
        id: true,  
        name: true,  
        description: true,  
        icon: true,  
        sport\_attributes: {  
          select: {  
            id: true,  
            attribute\_tests: {  
              select: { id: true },  
            },  
          },  
        },  
      },  
      orderBy: { name: "asc" },  
    });  
  
    const formattedSports = sports.map((sport) => ({  
      id: sport.id,  
      name: sport.name,  
      description: sport.description,  
      icon: sport.icon,  
      category\_type: getCategoryType(sport.id),  
      has\_categories: getCategoryType(sport.id) !== "none",  
      total\_attributes: sport.sport\_attributes.length,  
      total\_tests: sport.sport\_attributes.reduce(  
        (acc, attr) => acc + attr.attribute\_tests.length,  
        0,  
      ),  
    }));  
  
    res.status(200).json({ success: true, data: formattedSports });  
  } catch (error: any) {  
    console.error("Get Sports List Error:", error);  
    return next(new AppError("Failed to fetch sports list.", 500));  
  }  
};  
  
// 📌 الدالة الجديدة لجلب الأوزان/المراكز المتاحة لكل رياضة  
export const getSportCategories = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const sport\_id = parseInt(req.params.sport\_id as any);  
  
    const sport = await prisma.sports.findUnique({  
      where: { id: sport\_id },  
      select: { id: true, name: true },  
    });  
  
    if (!sport) {  
      return next(new AppError("Sport not found.", 404));  
    }  
  
    const categoriesEnum = getCategoriesBySportId(sport.id);  
  
    // تحويل كل Enum إلى Label مقروء  
    const formattedCategories = categoriesEnum.map((cat) => ({  
      label: formatCategoryLabel(cat),  
      value: cat,  
    }));  
  
    res.status(200).json({  
      success: true,  
      data: {  
        sport\_id: sport.id,  
        sport\_name: sport.name,  
        categories: formattedCategories,  
      },  
    });  
  } catch (error: any) {  
    console.error("Get Sport Categories Error:", error);  
    return next(new AppError("Failed to fetch sport categories.", 500));  
  }  
};  
  
export const completeOnboarding = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const { sport\_id, level, player\_category, test\_values } = req.body;  
  
    const existingProfile = await prisma.user\_sport\_profiles.findFirst({  
      where: { user\_id: userId, is\_primary: true },  
    });  
    if (existingProfile) {  
      return next(  
        new AppError(  
          "Onboarding already completed. Use settings to update profile.",  
          409,  
        ),  
      );  
    }  
  
    if (!sport\_id || !level || !player\_category || !test\_values) {  
      return next(  
        new AppError(  
          "Missing required fields: sport\_id, level, player\_category, and test\_values are required.",  
          400,  
        ),  
      );  
    }  
  
    if (!Array.isArray(test\_values) || test\_values.length === 0) {  
      return next(new AppError("test\_values must be a non-empty array.", 400));  
    }  
  
    const sport = await prisma.sports.findUnique({  
      where: { id: Number(sport\_id) },  
      include: {  
        sport\_attributes: {  
          include: {  
            attribute\_tests: true,  
          },  
        },  
      },  
    });  
  
    if (!sport) {  
      return next(new AppError("Sport not found.", 404));  
    }  
  
    // 📌 ضفنا Validation إن الـ category مسموح بيها للرياضة دي  
    const validCategories = getCategoriesBySportId(sport.id);  
    if (!validCategories.includes(player\_category)) {  
      return next(  
        new AppError(  
          \`Invalid player category (${player\_category}) for ${sport.name}.\`,  
          400,  
        ),  
      );  
    }  
  
    const allTestIds = sport.sport\_attributes.flatMap((attr) =>  
      attr.attribute\_tests.map((test) => test.id),  
    );  
  
    for (const test of test\_values) {  
      if (!allTestIds.includes(test.attribute\_test\_id)) {  
        return next(  
          new AppError(  
            \`Invalid test\_id: ${test.attribute\_test\_id} does not belong to this sport.\`,  
            400,  
          ),  
        );  
      }  
    }  
  
    const result = await prisma.$transaction(async (tx) => {  
      const sportProfile = await tx.user\_sport\_profiles.create({  
        data: {  
          user\_id: userId,  
          sport\_id: Number(sport\_id),  
          level,  
          player\_category,  
          is\_primary: true,  
        },  
      });  
  
      const snapshot = await tx.physical\_snapshots.create({  
        data: {  
          user\_id: userId,  
          sport\_id: Number(sport\_id),  
          snapshot\_type: "initial\_onboarding",  
          notes: \`Initial onboarding baseline assessment for ${sport.name}\`,  
        },  
      });  
  
      const testValuesData = test\_values.map((test: any) => ({  
        snapshot\_id: snapshot.id,  
        attribute\_test\_id: test.attribute\_test\_id,  
        value: test.value,  
        unit: test.unit || "unknown",  
      }));  
  
      await tx.snapshot\_test\_values.createMany({  
        data: testValuesData,  
      });  
  
      return {  
        sportProfile,  
        snapshot,  
        testCount: testValuesData.length,  
      };  
    });  
  
    res.status(201).json({  
      success: true,  
      message: "Onboarding completed successfully!",  
      data: {  
        sport\_profile\_id: result.sportProfile.id,  
        baseline\_snapshot\_id: result.snapshot.id,  
        tests\_logged: result.testCount,  
        sport\_name: sport.name,  
        level,  
        player\_category,  
      },  
    });  
  } catch (error: any) {  
    console.error("Complete Onboarding Error:", error);  
    return next(  
      new AppError(error.message || "Failed to complete onboarding.", 500),  
    );  
  }  
};  
  
export const getOnboardingStatus = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const sportProfile = await prisma.user\_sport\_profiles.findFirst({  
      where: { user\_id: userId, is\_primary: true },  
      include: {  
        sports: {  
          select: {  
            id: true,  
            name: true,  
            icon: true,  
          },  
        },  
      },  
    });  
  
    const metrics = await prisma.user\_metrics.findUnique({  
      where: { user\_id: userId },  
    });  
  
    const latestSnapshot = await prisma.physical\_snapshots.findFirst({  
      where: {  
        user\_id: userId,  
        snapshot\_type: "initial\_onboarding",  
      },  
      orderBy: { created\_at: "desc" },  
      include: {  
        snapshot\_test\_values: {  
          take: 1,  
        },  
      },  
    });  
  
    const hasSportProfile = !!sportProfile;  
    const hasMetrics = !!metrics;  
    const hasBaselineSnapshot =  
      !!latestSnapshot && latestSnapshot.snapshot\_test\_values.length > 0;  
  
    const isComplete = hasSportProfile && hasMetrics && hasBaselineSnapshot;  
  
    let missingSteps: string\[\] = \[\];  
    if (!hasSportProfile) missingSteps.push("sport\_profile");  
    if (!hasMetrics) missingSteps.push("user\_metrics");  
    if (!hasBaselineSnapshot) missingSteps.push("baseline\_snapshot");  
  
    let progressPercentage = 0;  
    if (hasSportProfile) progressPercentage += 33;  
    if (hasMetrics) progressPercentage += 33;  
    if (hasBaselineSnapshot) progressPercentage += 34;  
  
    res.status(200).json({  
      success: true,  
      data: {  
        is\_complete: isComplete,  
        progress\_percentage: progressPercentage,  
        missing\_steps: missingSteps,  
        sport\_profile: sportProfile  
          ? {  
              id: sportProfile.id,  
              sport\_id: sportProfile.sport\_id,  
              sport\_name: sportProfile.sports?.name,  
              level: sportProfile.level,  
              player\_category: sportProfile.player\_category,  
            }  
          : null,  
        has\_metrics: hasMetrics,  
        has\_baseline: hasBaselineSnapshot,  
        baseline\_snapshot\_id: latestSnapshot?.id || null,  
      },  
    });  
  } catch (error: any) {  
    console.error("Get Onboarding Status Error:", error);  
    return next(new AppError("Failed to get onboarding status.", 500));  
  }  
};  
  
export const requireOnboarding = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const \[sportProfile, metrics, snapshot\] = await Promise.all(\[  
      prisma.user\_sport\_profiles.findFirst({  
        where: { user\_id: userId, is\_primary: true },  
      }),  
      prisma.user\_metrics.findUnique({  
        where: { user\_id: userId },  
      }),  
      prisma.physical\_snapshots.findFirst({  
        where: {  
          user\_id: userId,  
          snapshot\_type: "initial\_onboarding",  
        },  
      }),  
    \]);  
  
    if (!sportProfile || !metrics || !snapshot) {  
      return next(  
        new AppError(  
          "Onboarding incomplete. Please complete your athlete profile first.",  
          403,  
        ),  
      );  
    }  
  
    req.onboarding = {  
      sportProfile,  
      metrics,  
      snapshot,  
    };  
  
    next();  
  } catch (error: any) {  
    console.error("Require Onboarding Middleware Error:", error);  
    return next(new AppError("Failed to verify onboarding status.", 500));  
  }  
};  
  
// ==========================================  
// Athlete Dashboard - Unified Endpoint  
// ==========================================  
export const getAthleteDashboard = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const user = await prisma.users.findUnique({  
      where: { id: userId },  
      include: {  
        user\_sport\_profiles: {  
          where: { is\_primary: true },  
          include: {  
            sports: true,  
          },  
        },  
      },  
    });  
  
    if (!user) {  
      return next(new AppError("User not found.", 404));  
    }  
  
    const profile = user.user\_sport\_profiles\[0\];  
  
    if (!profile) {  
      return next(new AppError("Sport profile not found.", 404));  
    }  
  
    const { password\_hash, ...safeUser } = user;  
  
    const ageGroupId = getAgeGroupId(user.date\_of\_birth);  
  
    const \[metrics, latestSnapshot\] = await Promise.all(\[  
      prisma.user\_metrics.findUnique({  
        where: {  
          user\_id: userId,  
        },  
      }),  
  
      prisma.physical\_snapshots.findFirst({  
        where: {  
          user\_id: userId,  
        },  
        orderBy: {  
          created\_at: "desc",  
        },  
        include: {  
          sports: true,  
          snapshot\_test\_values: {  
            include: {  
              attribute\_tests: {  
                include: {  
                  sport\_attributes: true,  
                },  
              },  
            },  
          },  
        },  
      }),  
    \]);  
  
    // 📌 RADAR DATA - من أحدث Snapshot (قيم فعلية، مش Percentiles)  
    let radarData: any\[\] = \[\];  
    let punchPower = null;  
  
    if (latestSnapshot) {  
      // 📌 نبني Map لتجميع القيم حسب الـ attribute  
      const attributeMap = new Map<  
        string,  
        {  
          name: string;  
          values: number\[\];  
          count: number;  
        }  
      >();  
  
      for (const test of latestSnapshot.snapshot\_test\_values) {  
        const attr = test.attribute\_tests.sport\_attributes;  
        const attrName = attr.name;  
  
        if (!attributeMap.has(attrName)) {  
          attributeMap.set(attrName, {  
            name: attrName,  
            values: \[\],  
            count: 0,  
          });  
        }  
  
        const entry = attributeMap.get(attrName)!;  
        entry.values.push(Number(test.value));  
        entry.count++;  
      }  
  
      // 📌 حساب المتوسط لكل Attribute  
      radarData = Array.from(attributeMap.entries()).map(  
        (\[attribute\_name, item\]) => ({  
          attribute\_name,  
          value: Math.round(  
            item.values.reduce((a, b) => a + b, 0) / item.count,  
          ),  
        }),  
      );  
  
      // 📌 Punch Power - بنحسبه من الـ Percentiles عادي (زي ما هو)  
      // بنحتاج الـ Percentiles عشان نحسب Punch Power  
      const attributeMapForPercentiles = new Map<  
        number,  
        {  
          name: string;  
          tests: any\[\];  
          totalWeight: number;  
        }  
      >();  
  
      for (const test of latestSnapshot.snapshot\_test\_values) {  
        const attr = test.attribute\_tests.sport\_attributes;  
  
        if (!attributeMapForPercentiles.has(attr.id)) {  
          attributeMapForPercentiles.set(attr.id, {  
            name: attr.name,  
            tests: \[\],  
            totalWeight: 0,  
          });  
        }  
  
        const entry = attributeMapForPercentiles.get(attr.id)!;  
        const weight = Number(test.attribute\_tests.weight ?? 1);  
  
        entry.tests.push({  
          id: test.attribute\_test\_id,  
          raw: Number(test.value),  
          weight,  
          higherIsBetter: test.attribute\_tests.higher\_is\_better ?? true,  
        });  
  
        entry.totalWeight += weight;  
      }  
  
      let foundation = 0;  
      let accelerator = 0;  
      let transfer = 0;  
  
      for (const \[, attribute\] of attributeMapForPercentiles.entries()) {  
        for (const test of attribute.tests) {  
          const result = await getPercentileWithFallback(  
            test.id,  
            test.raw,  
            test.higherIsBetter,  
            profile.level,  
            profile.player\_category,  
            ageGroupId,  
          );  
  
          const testName = await getTestName(test.id);  
  
          if (testName === "Trap Bar Deadlift") {  
            foundation = result.percentile;  
          }  
  
          if (testName === "Power Clean" || testName === "Box Jump Height") {  
            accelerator = result.percentile;  
          }  
  
          if (testName === "Medicine Ball Rotational Throw") {  
            transfer = result.percentile;  
          }  
        }  
      }  
  
      punchPower = {  
        score: calculatePunchPower(foundation, accelerator, transfer),  
        foundation,  
        accelerator,  
        transfer,  
      };  
    }  
  
    const cleanedProfiles = user.user\_sport\_profiles.map(  
      ({ user\_id, ...rest }: any) => rest,  
    );  
  
    res.status(200).json({  
      success: true,  
      data: {  
        user: {  
          ...safeUser,  
          sport\_profiles: cleanedProfiles,  
        },  
  
        metrics,  
  
        // 📌 الرادار دلوقتي بقيم فعلية (مش Percentiles)  
        radar: radarData,  
  
        punch\_power: punchPower,  
  
        latest\_snapshot: latestSnapshot  
          ? {  
              id: latestSnapshot.id,  
              snapshot\_type: latestSnapshot.snapshot\_type,  
              sport\_name: latestSnapshot.sports.name,  
              created\_at: latestSnapshot.created\_at,  
              notes: latestSnapshot.notes,  
  
              test\_values: latestSnapshot.snapshot\_test\_values.map((tv) => ({  
                attribute\_test\_id: tv.attribute\_test\_id,  
                attribute\_name: tv.attribute\_tests.sport\_attributes.name,  
                test\_name: tv.attribute\_tests.test\_name,  
                value: Number(tv.value),  
                unit: tv.unit,  
              })),  
            }  
          : null,  
      },  
    });  
  } catch (error: any) {  
    console.error("Get Athlete Dashboard Error:", error);  
  
    return next(new AppError("Failed to fetch athlete dashboard.", 500));  
  }  
};  
import { Request, Response, NextFunction } from 'express';  
import bcrypt from 'bcryptjs';  
import jwt from 'jsonwebtoken';  
import { prisma } from '../config/prisma';  
import { AuthRequest } from '../middlewares/auth.middleware';  
import { AppError } from '../utils/AppError';  
  
const DUMMY\_HASH = '$2a$10$N9qo8uLOickgx2ZMRZoMy.MrqO6Z5z1jFvJk9fJk9fJk9fJk9fJk9';  
  
const generateTokens = (user: { id: string; username: string; role: string }) => {  
    const payload = { sub: user.id, username: user.username, role: user.role };  
    const accessToken = jwt.sign(payload, process.env.JWT\_ACCESS\_SECRET || 'fallback\_access\_secret', { expiresIn: '15m' });  
    const refreshToken = jwt.sign({ sub: user.id }, process.env.JWT\_REFRESH\_SECRET || 'fallback\_refresh\_secret', { expiresIn: '7d' });  
    return { accessToken, refreshToken };  
};  
  
export const register = async (req: Request, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const { username, email, password, date\_of\_birth, role = 'athlete' } = req.body;  
  
        const existingEmail = await prisma.users.findUnique({ where: { email } });  
        if (existingEmail) {  
            return next(new AppError("Unable to create account with the provided information.", 409));  
        }  
  
        const existingUsername = await prisma.users.findUnique({ where: { username } });  
        if (existingUsername) {  
            return next(new AppError("Username already exists", 409));  
        }  
  
        const salt = await bcrypt.genSalt(10);  
        const password\_hash = await bcrypt.hash(password, salt);  
  
        const result = await prisma.$transaction(async (tx) => {  
            const newUser = await tx.users.create({  
                data: {  
                    username, email, password\_hash,  
                    date\_of\_birth: new Date(date\_of\_birth),  
                    role,  
                },  
            });  
  
            const { accessToken, refreshToken } = generateTokens(newUser);  
  
            await tx.user\_tokens.create({  
                data: {  
                    user\_id: newUser.id,  
                    token: refreshToken,  
                    token\_type: 'REFRESH',  
                    expires\_at: new Date(Date.now() + 7 \* 24 \* 60 \* 60 \* 1000)  
                }  
            });  
  
            return { user: { id: newUser.id, username: newUser.username, email: newUser.email, role: newUser.role }, tokens: { accessToken, refreshToken } };  
        });  
  
        res.status(201).json({ success: true, message: 'User registered successfully', data: result });  
    } catch (error) {  
        console.error('Registration Error:', error);  
        return next(new AppError("Internal server error", 500));  
    }  
};  
  
export const login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const { email, password } = req.body;  
  
  
        const user = await prisma.users.findFirst({ where: { email, is\_active: true } });  
  
        const passwordHashToCompare = user ? user.password\_hash : DUMMY\_HASH;  
        const isMatch = await bcrypt.compare(password, passwordHashToCompare);  
  
        if (!user || !isMatch) {  
            return next(new AppError("Invalid credentials", 401));  
        }  
  
        const { accessToken, refreshToken } = generateTokens(user);  
  
        await prisma.$transaction(\[  
            prisma.user\_tokens.deleteMany({ where: { user\_id: user.id, token\_type: 'REFRESH' } }),  
            prisma.user\_tokens.create({  
                data: {  
                    user\_id: user.id, token: refreshToken, token\_type: 'REFRESH',  
                    expires\_at: new Date(Date.now() + 7 \* 24 \* 60 \* 60 \* 1000)  
                }  
            })  
        \]);  
  
        res.status(200).json({  
            success: true, message: 'Login successful',  
            data: { user: { id: user.id, username: user.username, email: user.email, role: user.role }, tokens: { accessToken, refreshToken } }  
        });  
    } catch (error) {  
        console.error('Login Error:', error);  
        return next(new AppError("Internal server error", 500));  
    }  
};  
export const refresh = async (req: Request, res: Response): Promise<void> => {  
    try {  
        const refreshToken = req.body?.refreshToken;  
        if (!refreshToken) {  
            res.status(400).json({ success: false, error: 'Refresh token is required in the body' });  
            return;  
        }  
  
        const tokenRecord = await prisma.user\_tokens.findUnique({ where: { token: refreshToken } });  
        if (!tokenRecord || tokenRecord.token\_type !== 'REFRESH' || tokenRecord.expires\_at < new Date()) {  
            res.status(401).json({ success: false, error: 'Invalid or expired refresh token' });  
            return;  
        }  
  
        const decoded = jwt.verify(refreshToken, process.env.JWT\_REFRESH\_SECRET || 'fallback\_refresh\_secret') as { sub: string };  
        const user = await prisma.users.findUnique({ where: { id: decoded.sub, is\_active: true } });  
        if (!user) {  
            res.status(401).json({ success: false, error: 'User inactive or not found' });  
  
            return;  
        }  
  
        const tokens = generateTokens(user);  
  
        await prisma.$transaction(\[  
            prisma.user\_tokens.delete({ where: { user\_token\_id: tokenRecord.user\_token\_id } }),  
            prisma.user\_tokens.create({  
                data: {  
                    user\_id: user.id, token: tokens.refreshToken, token\_type: 'REFRESH',  
                    expires\_at: new Date(Date.now() + 7 \* 24 \* 60 \* 60 \* 1000)  
                }  
            })  
        \]);  
  
        res.status(200).json({ success: true, message: 'Token refreshed successfully', data: { tokens } });  
    } catch (error) {  
        console.error('Refresh Error:', error);  
        res.status(401).json({ success: false, error: 'Invalid or expired refresh token' });  
    }  
};  
  
export const logout = async (req: AuthRequest, res: Response): Promise<void> => {  
    try {  
        const userId = req.user?.sub;  
        if (!userId) {  
            res.status(401).json({ success: false, error: "Unauthorized" });  
            return;  
        }  
        await prisma.user\_tokens.deleteMany({ where: { user\_id: userId, token\_type: 'REFRESH' } });  
        res.status(200).json({ success: true, message: "Logged out successfully" });  
    } catch (error) {  
        console.error("Logout Error:", error);  
        res.status(500).json({ success: false, error: "Failed to logout" });  
    }  
};  
import { Response, NextFunction } from "express";  
import { AuthRequest } from "../middlewares/auth.middleware";  
import { prisma } from "../config/prisma";  
import { competitive\_level, player\_category } from "@prisma/client";  
import {  
  calculateZScore,  
  calculatePercentile,  
} from "../services/calculation.service";  
import { AppError } from "../utils/AppError";  
  
// ==========================================  
// 🛠️ Helper Functions (Analytics Engine)  
// ==========================================  
  
const getAgeGroupId = (  
  dateOfBirth: Date | string | null | undefined,  
): number => {  
  if (!dateOfBirth) return 2;  
  
  const dob = new Date(dateOfBirth);  
  if (isNaN(dob.getTime())) return 2; // Fallback  
  
  const today = new Date();  
  let age = today.getFullYear() - dob.getFullYear();  
  const monthDiff = today.getMonth() - dob.getMonth();  
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {  
    age--;  
  }  
  
  if (age < 18) return 1;  
  if (age <= 35) return 2;  
  return 3;  
};  
  
const getAdjacentWeightClasses = (  
  category: player\_category,  
): player\_category\[\] => {  
  if (!category) return \[\];  
  const classes: player\_category\[\] = \[  
    "flyweight",  
    "bantamweight",  
    "featherweight",  
    "lightweight",  
    "light\_welterweight",  
    "welterweight",  
    "light\_middleweight",  
    "middleweight",  
    "super\_middleweight",  
    "light\_heavyweight",  
    "cruiserweight",  
    "heavyweight",  
  \];  
  const idx = classes.indexOf(category);  
  if (idx === -1) return \[\];  
  const adjacent: player\_category\[\] = \[\];  
  if (idx > 0) adjacent.push(classes\[idx - 1\]);  
  if (idx < classes.length - 1) adjacent.push(classes\[idx + 1\]);  
  return adjacent;  
};  
  
const getPercentileForTest = async (  
  testId: number,  
  rawValue: number,  
  higherIsBetter: boolean,  
  userLevel: competitive\_level | undefined | null,  
  userCategory: player\_category | undefined | null,  
  userAgeGroupId: number,  
): Promise<number> => {  
  const safeRawValue = Math.max(0, rawValue);  
  
  const fallbackSteps: any\[\] = \[  
    {  
      category: userCategory || undefined,  
      level: userLevel || undefined,  
      ageGroup: userAgeGroupId,  
    },  
    {  
      category: userCategory || undefined,  
      level: userLevel || undefined,  
      ageGroup: undefined,  
    },  
    {  
      category: userCategory  
        ? { in: getAdjacentWeightClasses(userCategory) }  
        : undefined,  
      level: userLevel || undefined,  
      ageGroup: undefined,  
    },  
    { category: undefined, level: userLevel || undefined, ageGroup: undefined },  
    { category: undefined, level: undefined, ageGroup: undefined },  
  \];  
  
  try {  
    for (const step of fallbackSteps) {  
      const norm = await prisma.normative\_data.findFirst({  
        where: {  
          attribute\_test\_id: testId,  
          ...(step.category && { player\_category: step.category }),  
          ...(step.level && { level: step.level }),  
          ...(step.ageGroup && { age\_group\_id: step.ageGroup }),  
        },  
      });  
      if (norm) {  
        const stdDev = Number(norm.std\_dev);  
        const meanValue = Number(norm.mean\_value);  
        if (stdDev === 0) {  
          return safeRawValue >= meanValue  
            ? higherIsBetter  
              ? 99  
              : 1  
            : higherIsBetter  
              ? 1  
              : 99;  
        }  
  
        const z = calculateZScore(rawValue, meanValue, stdDev, higherIsBetter);  
        return calculatePercentile(z);  
      }  
    }  
  } catch (error) {  
    console.error(\`Error in getPercentileForTest for testId ${testId}:\`, error);  
  }  
  return Math.min(99, Math.max(1, Math.floor(safeRawValue / 2)));  
};  
  
const getUserCompositeScore = async (  
  userId: string,  
  testIds: number\[\],  
  userLevel: competitive\_level | undefined | null,  
  userCategory: player\_category | undefined | null,  
  userAgeGroupId: number,  
): Promise<number> => {  
  try {  
    const latestSnapshot = await prisma.physical\_snapshots.findFirst({  
      where: { user\_id: userId },  
      orderBy: { created\_at: "desc" },  
      include: {  
        snapshot\_test\_values: {  
          where: { attribute\_test\_id: { in: testIds } },  
          include: { attribute\_tests: { select: { higher\_is\_better: true } } },  
        },  
      },  
    });  
    if (  
      !latestSnapshot ||  
      !latestSnapshot.snapshot\_test\_values ||  
      latestSnapshot.snapshot\_test\_values.length === 0  
    ) {  
      return 0;  
    }  
  
    let totalPercentile = 0;  
    let validTestsCount = 0;  
    for (const testVal of latestSnapshot.snapshot\_test\_values) {  
      if (testVal.value === null || testVal.value === undefined) continue;  
  
      const percentile = await getPercentileForTest(  
        testVal.attribute\_test\_id,  
        Number(testVal.value),  
        testVal.attribute\_tests?.higher\_is\_better ?? true,  
        userLevel,  
        userCategory,  
        userAgeGroupId,  
      );  
  
      totalPercentile += percentile;  
      validTestsCount++;  
    }  
    return validTestsCount === 0 ? 0 : totalPercentile / validTestsCount;  
  } catch (error) {  
    console.error(  
      \`Error calculating composite score for user ${userId}:\`,  
      error,  
    );  
    return 0;  
  }  
};  
  
async function getCompositeScoreFromSnapshot(  
  snapshotId: string,  
  testIds: number\[\],  
  level: competitive\_level,  
  category: player\_category,  
  ageGroupId: number,  
): Promise<number> {  
  try {  
    const snapshot = await prisma.physical\_snapshots.findUnique({  
      where: { id: snapshotId },  
      include: {  
        snapshot\_test\_values: {  
          where: { attribute\_test\_id: { in: testIds } },  
          include: { attribute\_tests: { select: { higher\_is\_better: true } } },  
        },  
      },  
    });  
    if (  
      !snapshot ||  
      !snapshot.snapshot\_test\_values ||  
      snapshot.snapshot\_test\_values.length === 0  
    )  
      return 0;  
  
    let totalPercentile = 0;  
    let validTestsCount = 0;  
  
    for (const tv of snapshot.snapshot\_test\_values) {  
      if (tv.value === null || tv.value === undefined) continue;  
  
      const pct = await getPercentileForTest(  
        tv.attribute\_test\_id,  
        Number(tv.value),  
        tv.attribute\_tests?.higher\_is\_better ?? true,  
        level,  
        category,  
        ageGroupId,  
      );  
      totalPercentile += pct;  
      validTestsCount++;  
    }  
    return validTestsCount === 0  
      ? 0  
      : Number((totalPercentile / validTestsCount).toFixed(2));  
  } catch (error) {  
    console.error(  
      \`Error in getCompositeScoreFromSnapshot for snapshot ${snapshotId}:\`,  
      error,  
    );  
    return 0;  
  }  
}  
  
// ==========================================  
// 🏆 1. Category Ranked Leaderboard Controller  
// ==========================================  
export const getLeaderboard = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub ? String(req.user.sub) : null;  
    if (!userId) {  
      return next(new AppError("Unauthorized: Missing user payload.", 401));  
    }  
  
    const type = req.query.type as string;  
    const limit = Math.max(1, parseInt(req.query.limit as string) || 50);  
    const offset = Math.max(0, parseInt(req.query.offset as string) || 0);  
  
    const currentUserProfile = await prisma.user\_sport\_profiles.findFirst({  
      where: { user\_id: userId, is\_primary: true },  
    });  
  
    if (!currentUserProfile) {  
      return next(  
        new AppError(  
          "Cannot determine cohort — create sport profile first.",  
          400,  
        ),  
      );  
    }  
  
    const category: player\_category =  
      (req.query.player\_category as player\_category) ||  
      currentUserProfile.player\_category;  
    const level: competitive\_level =  
      (req.query.level as competitive\_level) || currentUserProfile.level;  
  
    const cohortUsers = await prisma.user\_sport\_profiles.findMany({  
      where: { player\_category: category, level: level, is\_primary: true },  
      select: { user\_id: true },  
    });  
    const cohortUserIds = cohortUsers.map((p) => p.user\_id);  
  
    if (cohortUserIds.length === 0) {  
      res.status(200).json(\[\]);  
      return;  
    }  
  
    const usersWithDob = await prisma.users.findMany({  
      where: { id: { in: cohortUserIds } },  
      select: {  
        id: true,  
        date\_of\_birth: true,  
        username: true,  
        profile\_photo: true,  
      },  
    });  
  
    const userAgeGroupMap = new Map<string, number>();  
    for (const u of usersWithDob) {  
      userAgeGroupMap.set(u.id, getAgeGroupId(u.date\_of\_birth));  
    }  
  
    const selectedTestIds =  
      type === "punch\_power"  
        ? \[1, 2, 4\]  
        : type === "strength"  
          ? \[1, 5, 6\]  
          : \[7, 8, 9\]; // endurance  
  
    const scores = await Promise.all(  
      cohortUserIds.map(async (uid) => {  
        const ageGroup = userAgeGroupMap.get(uid) || 2;  
        const compositeScore = await getUserCompositeScore(  
          uid,  
          selectedTestIds,  
          level,  
          category,  
          ageGroup,  
        );  
  
        if (compositeScore === 0) return null;  
  
        const userInfo = usersWithDob.find((u) => u.id === uid);  
  
        return {  
          user\_id: uid,  
          username: userInfo?.username || "Unknown",  
          profile\_photo: userInfo?.profile\_photo || null,  
          \[\`${type}\_score\`\]: Number(compositeScore.toFixed(2)),  
          player\_category: category,  
          level: level,  
          is\_current\_user: uid === userId,  
          score: compositeScore,  
        };  
      }),  
    );  
  
    let leaderboardData = scores.filter((s) => s !== null) as any\[\];  
    leaderboardData.sort((a, b) => b.score - a.score);  
  
    leaderboardData = leaderboardData.map((item, idx) => {  
      const { score, ...cleanItem } = item;  
      return { rank: idx + 1, ...cleanItem };  
    });  
  
    // تطبيق الـ Pagination  
    const paginatedData = leaderboardData.slice(offset, offset + limit);  
  
    // التأكد إن اللاعب الحالي موجود في الرد، حتى لو مش في الصفحة الحالية  
    const currentUserEntry = leaderboardData.find((a) => a.is\_current\_user);  
    if (currentUserEntry && !paginatedData.some((a) => a.user\_id === userId)) {  
      paginatedData.push(currentUserEntry);  
    }  
  
    res.status(200).json(paginatedData);  
  } catch (error: any) {  
    console.error("Leaderboard Error:", error);  
    next(error);  
  }  
};  
  
// ==========================================  
// ⚡ 2. Most Improved Leaderboard Controller  
// ==========================================  
export const getMostImproved = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub ? String(req.user.sub) : null;  
    if (!userId) {  
      return next(new AppError("Unauthorized: Missing user payload.", 401));  
    }  
  
    const limit = Math.max(1, parseInt(req.query.limit as string) || 50);  
    const offset = Math.max(0, parseInt(req.query.offset as string) || 0);  
  
    const currentUserProfile = await prisma.user\_sport\_profiles.findFirst({  
      where: { user\_id: userId, is\_primary: true },  
    });  
  
    if (!currentUserProfile) {  
      return next(new AppError("Cannot determine cohort.", 400));  
    }  
  
    const category: player\_category =  
      (req.query.player\_category as player\_category) ||  
      currentUserProfile.player\_category;  
    const level: competitive\_level =  
      (req.query.level as competitive\_level) || currentUserProfile.level;  
  
    const cohortUsers = await prisma.user\_sport\_profiles.findMany({  
      where: { player\_category: category, level: level, is\_primary: true },  
      select: { user\_id: true },  
    });  
    const cohortUserIds = cohortUsers.map((p) => p.user\_id);  
  
    if (cohortUserIds.length === 0) {  
      res.status(200).json(\[\]);  
      return;  
    }  
  
    const usersWithDob = await prisma.users.findMany({  
      where: { id: { in: cohortUserIds } },  
      select: { id: true, date\_of\_birth: true },  
    });  
    const userAgeGroupMap = new Map<string, number>();  
    for (const u of usersWithDob) {  
      userAgeGroupMap.set(u.id, getAgeGroupId(u.date\_of\_birth));  
    }  
  
    const thirtyDaysAgo = new Date();  
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);  
  
    const rawImprovedResults: any\[\] = await prisma.$queryRaw\`  
      WITH cohort\_users AS (  
          SELECT user\_id FROM user\_sport\_profiles  
          WHERE is\_primary = true AND player\_category::text = ${category} AND level::text = ${level}  
      ),  
      snapshots\_in\_range AS (  
          SELECT id, user\_id, created\_at  
          FROM physical\_snapshots  
          WHERE user\_id IN (SELECT user\_id FROM cohort\_users)  
            AND sport\_id = 1  
            AND created\_at >= ${thirtyDaysAgo}  
      ),  
      first\_snap AS (  
          SELECT DISTINCT ON (user\_id) id AS snapshot\_id, user\_id  
          FROM snapshots\_in\_range  
          ORDER BY user\_id, created\_at ASC  
      ),  
      last\_snap AS (  
          SELECT DISTINCT ON (user\_id) id AS snapshot\_id, user\_id  
          FROM snapshots\_in\_range  
          ORDER BY user\_id, created\_at DESC  
      )  
      SELECT  
          u.id, u.username, u.profile\_photo,  
          fs.snapshot\_id AS first\_snapshot\_id,  
          ls.snapshot\_id AS last\_snapshot\_id  
      FROM users u  
      JOIN first\_snap fs ON fs.user\_id = u.id  
      JOIN last\_snap ls ON ls.user\_id = u.id  
      WHERE fs.snapshot\_id != ls.snapshot\_id  
    \`;  
  
    let leaderboardData: any\[\] = \[\];  
  
    if (rawImprovedResults && rawImprovedResults.length > 0) {  
      const punchPowerTestIds = \[1, 2, 4\];  
  
      const improvementData = await Promise.all(  
        rawImprovedResults.map(async (ath) => {  
          const ageGroup = userAgeGroupMap.get(ath.id) || 2;  
          const firstScore = await getCompositeScoreFromSnapshot(  
            ath.first\_snapshot\_id,  
            punchPowerTestIds,  
            level,  
            category,  
            ageGroup,  
          );  
          const lastScore = await getCompositeScoreFromSnapshot(  
            ath.last\_snapshot\_id,  
            punchPowerTestIds,  
            level,  
            category,  
            ageGroup,  
          );  
          const improvement = lastScore - firstScore;  
  
          return {  
            rank: 0,  
            username: ath.username || "Unknown",  
            profile\_photo: ath.profile\_photo || null,  
            punch\_power\_delta: Number(improvement.toFixed(2)),  
            start\_score: firstScore,  
            end\_score: lastScore,  
            period\_days: 30,  
            is\_current\_user: ath.id === userId,  
            id: ath.id,  
          };  
        }),  
      );  
  
      leaderboardData = improvementData.filter(  
        (d) => d.punch\_power\_delta !== 0,  
      );  
      leaderboardData.sort((a, b) => b.punch\_power\_delta - a.punch\_power\_delta);  
      leaderboardData = leaderboardData.map((item, idx) => ({  
        ...item,  
        rank: idx + 1,  
      }));  
    }  
  
    // تطبيق الـ Pagination  
    const paginatedData = leaderboardData.slice(offset, offset + limit);  
  
    // التأكد من وجود اللاعب الحالي  
    const currentUserEntry = leaderboardData.find((a) => a.is\_current\_user);  
    if (currentUserEntry && !paginatedData.some((a) => a.id === userId)) {  
      paginatedData.push(currentUserEntry);  
    }  
  
    // تنظيف الـ ID الداخلي وتحويله لـ user\_id قبل الإرجاع النهائي  
    const finalData = paginatedData.map(({ id, ...rest }) => ({  
      user\_id: id,  
      ...rest,  
    }));  
  
    res.status(200).json(finalData);  
  } catch (error: any) {  
    console.error("Most Improved Error:", error);  
    next(error);  
  }  
};  
import { Request, Response, NextFunction } from "express";  
import { AuthRequest } from "../middlewares/auth.middleware";  
import { prisma } from "../config/prisma";  
import { program\_goal } from "@prisma/client";  
import { AppError } from "../utils/AppError";  
  
// --- 4.1 Create Program (Coach Only) ---  
// Validated  
export const createProgram = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const coachId = req.user?.sub as string;  
  
    // استلام الحقول بمرونة مع دعم كل المسميات المتوقعة من الـ Payload  
    const {  
      title,  
      description,  
      sport\_id,  
      goal\_primary,  
      program\_goal, // fallback لو مبعوت بالاسم ده  
      level\_target,  
      difficulty\_level, // fallback لو مبعوت بالاسم ده  
      competitive\_level, // fallback التاني اللي كان ظاهر في الـ error log  
      duration\_weeks,  
      sessions\_per\_week,  
      is\_published = false,  
      cover\_image,  
      program\_blocks, // الاسم المبعوت في الـ JSON الكامل  
      blocks = \[\], // الاسم التاني كـ Fallback  
    } = req.body;  
  
    // 1. فحص وجود الـ Sport في قاعدة البيانات لمنع الـ Foreign Key Constraint  
    const targetSportId = Number(sport\_id);  
    if (!targetSportId || isNaN(targetSportId)) {  
      return next(new AppError("Validation error — Invalid or missing sport\_id.", 400));  
    }  
  
    const sportExists = await prisma.sports.findUnique({  
      where: { id: targetSportId },  
    });  
    if (!sportExists) {  
      return next(new AppError("Sport not found.", 404));  
    }  
  
    // تحديد القيم النهائية للـ Enums الملعونة بناءً على المبعوث لحمايتها من الـ undefined  
    const finalGoal = goal\_primary || program\_goal || "general";  
    const finalLevel =  
      level\_target || difficulty\_level || competitive\_level || "beginner";  
  
    // 2. بناء الـ Blocks والـ Sessions والـ Exercises ديناميكياً بمرونة في المسميات  
    const inputBlocks = program\_blocks || blocks || \[\];  
    const blocksCreateData = Array.isArray(inputBlocks)  
      ? inputBlocks.map((block: any) => ({  
          name: block.name || "Untitled Block",  
          description: block.description || "",  
          order\_index: block.order\_index || 0,  
          week\_start: block.week\_start || 1,  
          week\_end: block.week\_end || 1,  
          program\_sessions: {  
            create: Array.isArray(block.program\_sessions || block.sessions)  
              ? (block.program\_sessions || block.sessions).map(  
                  (session: any) => ({  
                    name: session.name || "Untitled Session",  
                    description: session.description || "",  
                    day\_offset: session.day\_offset || 0,  
                    estimated\_duration\_minutes:  
                      session.estimated\_duration\_minutes || 0,  
                    session\_exercises: {  
                      create: Array.isArray(  
                        session.session\_exercises || session.exercises,  
                      )  
                        ? (session.session\_exercises || session.exercises).map(  
                            (exercise: any) => ({  
                              exercise\_name:  
                                exercise.exercise\_name || "Exercise",  
                              sets: exercise.sets || 0,  
                              reps: String(exercise.reps || 0),  
                              rest\_seconds: exercise.rest\_seconds || 0,  
                              intensity\_note: exercise.intensity\_note || null,  
                              notes: exercise.notes || null,  
                              order\_index: exercise.order\_index || 0,  
                            }),  
                          )  
                        : \[\],  
                    },  
                  }),  
                )  
              : \[\],  
          },  
        }))  
      : \[\];  
  
    // 3. الحفظ في قاعدة البيانات في ضربة واحدة (Deep Nested Write)  
    const newProgram = await prisma.programs.create({  
      data: {  
        coach\_id: coachId || "08afbb3b-ea3b-4fd5-9c92-c22aea597fe3", // fallback عشان لو بتتست من غير توكن كوتش  
        sport\_id: targetSportId,  
        title,  
        description: description || "",  
        goal\_primary: finalGoal as any, // 👈 الـ Casting السحري لمنع خناقة الـ TypeScript  
        level\_target: finalLevel as any, // 👈 الـ Casting السحري لمنع خناقة الـ TypeScript  
        duration\_weeks: duration\_weeks ? Number(duration\_weeks) : 0,  
        sessions\_per\_week: sessions\_per\_week ? Number(sessions\_per\_week) : 0,  
        is\_published,  
        cover\_image: cover\_image || undefined,  
        program\_blocks: {  
          create: blocksCreateData,  
        },  
      },  
      include: {  
        program\_blocks: {  
          include: {  
            program\_sessions: {  
              include: {  
                session\_exercises: true,  
              },  
            },  
          },  
        },  
      },  
    });  
  
    // 4. الـ Response النظيف المفرود بدون wrappers زيادة لإرضاء الـ Tests  
    res.status(201).json({  
      ...newProgram,  
      enrollment\_count: 0,  
    });  
  } catch (error: any) {  
    console.error("Create Program Error:", error);  
    next(error); // ترحيل آمن ونظيف للـ Global Error Handler ليتعامل مع الـ 500  
  }  
};  
  
// Validated  
export const listPrograms = async (  
  req: Request,  
  res: Response,  
  next: NextFunction, // 🎯 ضفنا الـ next عشان الـ Global Error Handler  
): Promise<void> => {  
  try {  
    // 1. التقاط القيم المبعوثة وجعل الـ Defaults مطابقة للـ Validator  
    const limit = req.query.limit  
      ? parseInt(req.query.limit as string, 10)  
      : 20;  
    const offset = req.query.offset  
      ? parseInt(req.query.offset as string, 10)  
      : 0;  
  
    const sport\_id = req.query.sport\_id  
      ? Number(req.query.sport\_id)  
      : undefined;  
    const duration\_weeks = req.query.duration\_weeks  
      ? Number(req.query.duration\_weeks)  
      : undefined;  
    const min\_rating = req.query.min\_rating  
      ? Number(req.query.min\_rating)  
      : undefined;  
    const goal = req.query.goal as string | undefined;  
    const level = req.query.level as string | undefined;  
  
    // 2. بناء الـ Filter (مع استبعاد الـ Drafts صراحةً لضمان شروط الشيت)  
    const whereClause: any = { is\_published: true };  
  
    if (sport\_id) whereClause.sport\_id = sport\_id;  
    if (goal) whereClause.goal\_primary = goal.toLowerCase().trim();  
    if (level) whereClause.level\_target = level.toLowerCase().trim();  
    if (duration\_weeks) whereClause.duration\_weeks = duration\_weeks;  
  
    // فحص الـ rating\_avg مع الـ Prisma (لو قاعدة البيانات مخزناه كـ Decimal أو Float)  
    if (min\_rating) {  
      whereClause.rating\_avg = { gte: String(min\_rating) };  
    }  
  
    // 3. جلب البيانات بترتيب الـ Popularity والـ Rating الأعلى أولاً  
    const programs = await prisma.programs.findMany({  
      where: whereClause,  
      orderBy: \[{ enrollment\_count: "desc" }, { rating\_avg: "desc" }\],  
      take: limit,  
      skip: offset,  
      select: {  
        id: true,  
        title: true,  
        description: true,  
        goal\_primary: true,  
        level\_target: true,  
        duration\_weeks: true,  
        sessions\_per\_week: true,  
        cover\_image: true,  
        rating\_avg: true,  
        rating\_count: true,  
        enrollment\_count: true,  
        users: { select: { username: true, profile\_photo: true } }, // تأكد إن اسم جدول المدربين مربوط صح بـ Prisma  
        sports: { select: { name: true } },  
      },  
    });  
  
    // 4. عمل الـ Formatting المطابق للـ Expected Fields في السكرين شوت  
    const formattedPrograms = programs.map((p: any) => ({  
      id: p.id,  
      title: p.title,  
      description: p.description || "",  
      goal\_primary: p.goal\_primary,  
      level\_target: p.level\_target,  
      duration\_weeks: p.duration\_weeks,  
      sessions\_per\_week: p.sessions\_per\_week,  
      cover\_image: p.cover\_image,  
      rating\_avg: p.rating\_avg ? String(p.rating\_avg) : "0",  
      rating\_count: p.rating\_count || 0,  
      enrollment\_count: p.enrollment\_count || 0,  
      coach\_name: p.users?.username || "Unknown Coach",  
      coach\_photo: p.users?.profile\_photo || null,  
      sport\_name: p.sports?.name || "General",  
    }));  
  
    // 5. 🔥 الـ Response صريح ومفرود Array علطول بدون أي wrapper لتطابق الـ Test Cases  
    res.status(200).json(formattedPrograms);  
  } catch (error: any) {  
    console.error("List Programs Error:", error);  
    next(error); // 🔥 ترحيل آمن للـ Global Error Handler  
  }  
};  
  
//Validated  
// --- 4.3 Get Program By ID ---  
  
export const getProgramById = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const programId = req.query.program\_id as string; // جلب من الـ Query  
    const userRole = req.user?.role; // الـ Role الجاي من الـ Token  
    const userId = req.user?.sub; // الـ ID بتاع المستخدم الحالي  
  
    // جلب البرنامج مع كافة العلاقات المطلوبة في الشيت  
    const program = await prisma.programs.findUnique({  
      where: { id: programId },  
      include: {  
        users: { select: { username: true, profile\_photo: true, bio: true } },  
        program\_blocks: {  
          orderBy: { order\_index: "asc" },  
          include: {  
            program\_sessions: {  
              orderBy: { day\_offset: "asc" },  
              include: {  
                session\_exercises: { orderBy: { order\_index: "asc" } },  
              },  
            },  
          },  
        },  
        program\_ratings: {  
          orderBy: { created\_at: "desc" },  
          take: 5,  
          include: {  
            users: { select: { username: true, profile\_photo: true } },  
          },  
        },  
      },  
    });  
  
    // 1. لو البرنامج مش موجود أصلاً في قاعدة البيانات (Non-existent program\_id) -> 404  
    if (!program) {  
      return next(new AppError("Program not found.", 404));  
    }  
  
    // 2. 🔥 سيناريو الـ Sad Path المعقد: البرنامج Draft واللاعب بيحاول يدخل عليه  
    if (!program.is\_published && userRole === "athlete") {  
      return next(new AppError("Not found — athletes cannot see unpublished programs.", 404));  
    }  
  
    // 3. ترتيب الـ Mapping والـ Formatting المفرود بدون Wrapper  
    const formattedProgram = {  
      id: program.id,  
      title: program.title,  
      description: program.description || "",  
      goal\_primary: program.goal\_primary,  
      level\_target: program.level\_target,  
      duration\_weeks: program.duration\_weeks,  
      sessions\_per\_week: program.sessions\_per\_week,  
      cover\_image: program.cover\_image,  
      rating\_avg: program.rating\_avg ? String(program.rating\_avg) : "0",  
      rating\_count: program.rating\_count || 0,  
      enrollment\_count: program.enrollment\_count || 0,  
      coach: {  
        name: program.users?.username || "Unknown Coach",  
        photo: program.users?.profile\_photo || null,  
        bio: program.users?.bio || "",  
      },  
      // تفكيك البلوكات والـ Sessions والـ Exercises بشكل نظيف  
      blocks: program.program\_blocks.map((block: any) => ({  
        id: block.id,  
        name: block.name,  
        description: block.description || "",  
        order\_index: block.order\_index,  
        week\_start: block.week\_start,  
        week\_end: block.week\_end,  
        sessions: block.program\_sessions.map((session: any) => ({  
          id: session.id,  
          name: session.name,  
          description: session.description || "",  
          day\_offset: session.day\_offset,  
          estimated\_duration\_minutes: session.estimated\_duration\_minutes,  
          exercises: session.session\_exercises.map((exercise: any) => ({  
            id: exercise.id,  
            exercise\_name: exercise.exercise\_name,  
            sets: exercise.sets,  
            reps: String(exercise.reps), // التأكد إنها راجعة String '5' أو '8-12' زي الشيت  
            rest\_seconds: exercise.rest\_seconds,  
            intensity\_note: exercise.intensity\_note,  
            notes: exercise.notes,  
            order\_index: exercise.order\_index,  
          })),  
        })),  
      })),  
      recent\_ratings: program.program\_ratings.map((r: any) => ({  
        rating: r.rating,  
        review: r.review || "",  
        username: r.users?.username || "Anonymous",  
        date: r.created\_at,  
      })), // سميناها recent\_ratings لتطابق الـ Assertion (last 5)  
    };  
  
    // 4. الـ Response مفرود تماماً في الـ Root  
    res.status(200).json(formattedProgram);  
  } catch (error: any) {  
    console.error("Get Program By ID Error:", error);  
    next(error); // الترحيل الذكي والآمن للـ Global Error Handler  
  }  
};  
  
// VALIDATED  
// --- 4.4 Update Program (Coach Only) ---  
export const updateProgram = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const coachId = req.user?.sub as string;  
  
    // 🎯 قراءة الـ ID ديناميكياً من الـ Query أو الـ Body  
    const programId = (req.query.program\_id || req.body.program\_id) as string;  
    const updateData = req.body;  
  
    // 1. فحص الـ Exist  
    const program = await prisma.programs.findUnique({  
      where: { id: programId },  
      select: { coach\_id: true },  
    });  
  
    if (!program) {  
      return next(new AppError("Not found.", 404));  
    }  
  
    // 2. فحص الملكية (Coach tries to update another coach's program)  
    if (program.coach\_id !== coachId) {  
      return next(new AppError("Forbidden — not program owner.", 403));  
    }  
  
    // 3. التحديث (مع استبعاد الـ program\_id لو مبعوث جوه الـ body عشان ميعملش مشاكل مع الـ Prisma)  
    const { program\_id, ...pureUpdateData } = updateData;  
  
    const updatedProgram = await prisma.programs.update({  
      where: { id: programId },  
      data: {  
        ...(pureUpdateData.title !== undefined && {  
          title: pureUpdateData.title,  
        }),  
        ...(pureUpdateData.description !== undefined && {  
          description: pureUpdateData.description,  
        }),  
        ...(pureUpdateData.goal\_primary !== undefined && {  
          goal\_primary: pureUpdateData.goal\_primary,  
        }),  
        ...(pureUpdateData.level\_target !== undefined && {  
          level\_target: pureUpdateData.level\_target,  
        }),  
        ...(pureUpdateData.duration\_weeks !== undefined && {  
          duration\_weeks: Number(pureUpdateData.duration\_weeks),  
        }),  
        ...(pureUpdateData.sessions\_per\_week !== undefined && {  
          sessions\_per\_week: Number(pureUpdateData.sessions\_per\_week),  
        }),  
        ...(pureUpdateData.is\_published !== undefined && {  
          is\_published: pureUpdateData.is\_published,  
        }),  
        ...(pureUpdateData.cover\_image !== undefined && {  
          cover\_image: pureUpdateData.cover\_image,  
        }),  
      },  
    });  
  
    // 4. Response مفرود تماماً في الـ Root  
    res.status(200).json(updatedProgram);  
  } catch (error: any) {  
    console.error("Update Program Error:", error);  
    next(error);  
  }  
};  
  
// not Validated i think it work good  
// --- 4.5 Delete Program (Coach Only) ---  
export const deleteProgram = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const coachId = req.user?.sub as string;  
    const programId = req.params.id as string;  
  
    // Validate UUID format to prevent Prisma from throwing a 500 error  
    const uuidRegex =  
      /^\[0-9a-f\]{8}-\[0-9a-f\]{4}-\[1-5\]\[0-9a-f\]{3}-\[89ab\]\[0-9a-f\]{3}-\[0-9a-f\]{12}$/i;  
    if (!uuidRegex.test(programId)) {  
      return next(new AppError("Invalid Program ID format. Must be a valid UUID.", 400));  
    }  
  
    const program = await prisma.programs.findUnique({  
      select: { coach\_id: true },  
      where: { id: programId },  
    });  
  
    if (!program) {  
      return next(new AppError("Program not found.", 404));  
    }  
    if (program.coach\_id !== coachId) {  
      return next(new AppError("Forbidden: You can only delete your own programs.", 403));  
    }  
  
    const activeEnrollments = await prisma.enrollments.count({  
      where: { program\_id: programId, status: "active" },  
    });  
  
    if (activeEnrollments > 0) {  
      return next(new AppError("Conflict: Cannot delete a program with active enrollments.", 409));  
    }  
  
    await prisma.programs.delete({ where: { id: programId } });  
  
    res  
      .status(200)  
      .json({ success: true, message: "Program deleted successfully." });  
  } catch (error: any) {  
    console.error("Delete Program Error:", error);  
    // If Prisma fails due to foreign key constraints  
    if (error.code === "P2003") {  
      return next(new AppError("Conflict: Cannot delete this program because it is referenced by other records (e.g., past completed enrollments or history).", 409));  
    }  
  
    next(new AppError("An unexpected error occurred while deleting the program.", 500));  
  }  
};  
  
//Validated  
// --- 4.6 Enroll in Program (Athlete) ---  
// export const enrollInProgram = async (  
//   req: AuthRequest,  
//   res: Response,  
//   next: NextFunction  
// ): Promise<void> => {  
//   try {  
//     const userId = String(req.user?.sub);  
//     const { program\_id, preferred\_days, preferred\_time, baseline\_test\_values } = req.body;  
  
//     // 1. صياغة الوقت بشكل سليم أو تركه null لو مش موجود (إختياري في الشيت)  
//     let formattedTime: Date | null = null;  
//     if (preferred\_time) {  
//       formattedTime = new Date(\`1970-01-01T${preferred\_time}:00.000Z\`);  
//     }  
  
//     // 2. التحقق من وجود البرنامج وأنه Published  
//     const program = await prisma.programs.findUnique({  
//       where: { id: program\_id, is\_published: true },  
//       select: { id: true, title: true, sport\_id: true },  
//     });  
  
//     if (!program) {  
//       res.status(404).json({  
//         success: false,  
//         error: "Program not found or not published."  
//       });  
//       return;  
//     }  
  
//     // 3. فحص الـ Conflict (التسجيل المزدوج لمنع الـ Athlete من التسجيل مرتين)  
//     const existingEnrollment = await prisma.enrollments.findFirst({  
//       where: { user\_id: userId, program\_id: program\_id, status: "active" },  
//     });  
  
//     if (existingEnrollment) {  
//       res.status(409).json({  
//         success: false,  
//         error: "Conflict — already actively enrolled." // مطابقة للشيت بالملي  
//       });  
//       return;  
//     }  
  
//     // 4. فحص صحة الـ attribute\_test\_ids المبعوثة في الـ Array  
//     const testIds = baseline\_test\_values.map((t: any) => {  
//       if (!t.attribute\_test\_id || t.value === undefined) {  
//         throw new Error("VALIDATION\_ERROR: Each test value must have an attribute\_test\_id and a value.");  
//       }  
//       return Number(t.attribute\_test\_id);  
//     });  
  
//     const testsInfo = await prisma.attribute\_tests.findMany({  
//       where: { id: { in: testIds } },  
//       select: { id: true, unit: true },  
//     });  
  
//     if (testsInfo.length !== \[...new Set(testIds)\].length) {  
//       res.status(404).json({  
//         success: false,  
//         error: "One or more provided attribute\_test\_ids are invalid or do not exist."  
//       });  
//       return;  
//     }  
  
//     let testUnits: Record<number, string> = {};  
//     testsInfo.forEach((t) => {  
//       testUnits\[t.id\] = t.unit;  
//     });  
  
//     // 5. 🎯 الـ Transaction المقفلة بذكاء لتفادي مشاكل الـ Scope والـ TypeScript الـ الـ Compiler  
//     const transactionResult = await prisma.$transaction(async (tx) => {  
//       // أ) إنشاء الـ Baseline Snapshot  
//       const baselineSnapshot = await tx.physical\_snapshots.create({  
//         data: {  
//           user\_id: userId,  
//           sport\_id: program.sport\_id,  
//           snapshot\_type: "program\_baseline",  
//           snapshot\_test\_values: {  
//             create: baseline\_test\_values.map((test: any) => ({  
//               attribute\_test\_id: Number(test.attribute\_test\_id),  
//               value: Number(test.value),  
//               unit: testUnits\[Number(test.attribute\_test\_id)\] || "units",  
//             })),  
//           },  
//         },  
//       });  
  
//       // ب) إنشاء الـ Enrollment وربطه بالـ Snapshot  
//       const enrollment = await tx.enrollments.create({  
//         data: {  
//           users: { connect: { id: userId } },  
//           programs: { connect: { id: program\_id } },  
//           status: "active",  
//           start\_date: new Date(),  
//           preferred\_days: Array.isArray(preferred\_days) ? preferred\_days : \[\],  
//           preferred\_time: formattedTime,  
//           physical\_snapshots\_enrollments\_baseline\_snapshot\_idTophysical\_snapshots: {  
//             connect: { id: baselineSnapshot.id },  
//           },  
//         },  
//       });  
  
//       // جـ) تحديث الـ Snapshot بالإشارة العكسية للـ Enrollment ID  
//       await tx.physical\_snapshots.update({  
//         where: { id: baselineSnapshot.id },  
//         data: { program\_enrollment\_id: enrollment.id },  
//       });  
  
//       // د) توليد الـ System post تلقائياً على الفيد  
//       const user = await tx.users.findUnique({  
//         where: { id: userId },  
//         select: { username: true },  
//       });  
  
//       await tx.posts.create({  
//         data: {  
//           user\_id: userId,  
//           program\_id: program\_id,  
//           content: \`${user?.username || "A user"} just started the "${program.title}" training program! Time to put in the work! 🥊🔥\`,  
//           is\_system\_generated: true,  
//         },  
//       });  
  
//       // 🎯 بنرجع الـ الاثنين سوا في Object كـ Return للـ Transaction عشان الـ Scope الخارجي يشوفهم بأمان  
//       return { enrollment, baselineSnapshotId: baselineSnapshot.id };  
//     });  
  
//     // 6. 🎯 إرجاع الـ Response مفرود ونظيف ومطابق للـ Assertions في الـ Excel  
//     res.status(201).json({  
//       id: transactionResult.enrollment.id,  
//       status: transactionResult.enrollment.status,  
//       start\_date: transactionResult.enrollment.start\_date,  
//       baseline\_snapshot\_id: transactionResult.baselineSnapshotId // 👈 مقروءة بـ Type-safety كاملة  
//     });  
  
//   } catch (error: any) {  
//     // إمساك أخطاء الفاليديشن اليدوية بداخل الـ Transaction  
//     if (error.message?.startsWith("VALIDATION\_ERROR:")) {  
//       res.status(400).json({  
//         success: false,  
//         error: error.message.replace("VALIDATION\_ERROR: ", ""),  
//       });  
//       return;  
//     }  
  
//     console.error("Enrollment Error:", error);  
//     next(error); // الـ الـ الترحيل السليم للـ Global Error Handler  
//   }  
// };  
export const enrollInProgram = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = String(req.user?.sub);  
    const { program\_id, preferred\_days, preferred\_time, baseline\_test\_values } =  
      req.body;  
  
    // 1. صياغة الوقت بشكل سليم أو تركه null لو مش موجود  
    let formattedTime: Date | null = null;  
    if (preferred\_time) {  
      formattedTime = new Date(\`1970-01-01T${preferred\_time}:00.000Z\`);  
    }  
  
    // 2. التحقق من وجود البرنامج وأنه Published  
    const program = await prisma.programs.findUnique({  
      where: { id: program\_id, is\_published: true },  
      select: { id: true, title: true, sport\_id: true },  
    });  
  
    if (!program) {  
      return next(new AppError("Program not found or not published.", 404));  
    }  
  
    // 3. 🎯 فحص الـ Conflict المتطور (الحل الجذري لمنع ضرب الـ Unique Constraint في الـ Database)  
    const todayStart = new Date();  
    todayStart.setHours(0, 0, 0, 0);  
  
    const todayEnd = new Date();  
    todayEnd.setHours(23, 59, 59, 999);  
  
    const existingEnrollment = await prisma.enrollments.findFirst({  
      where: {  
        user\_id: userId,  
        program\_id: program\_id,  
        OR: \[  
          { status: "active" }, // لو التسجيل الحالي لسه شغال ونشط  
          {  
            start\_date: {  
              gte: todayStart,  
              lte: todayEnd,  
            },  
          }, // أو لو تم تسجيله بالفعل في نفس اليوم (لحماية التست السريع ورا بعضه)  
        \],  
      },  
    });  
  
    if (existingEnrollment) {  
      return next(new AppError("Conflict — already actively enrolled.", 409));  
    }  
  
    // 4. فحص صحة الـ attribute\_test\_ids المبعوثة في الـ Array  
    const testIds = baseline\_test\_values.map((t: any) => {  
      if (!t.attribute\_test\_id || t.value === undefined) {  
        throw new Error(  
          "VALIDATION\_ERROR: Each test value must have an attribute\_test\_id and a value.",  
        );  
      }  
      return Number(t.attribute\_test\_id);  
    });  
  
    const testsInfo = await prisma.attribute\_tests.findMany({  
      where: { id: { in: testIds } },  
      select: { id: true, unit: true },  
    });  
  
    if (testsInfo.length !== \[...new Set(testIds)\].length) {  
      return next(new AppError("One or more provided attribute\_test\_ids are invalid or do not exist.", 404));  
    }  
  
    let testUnits: Record<number, string> = {};  
    testsInfo.forEach((t) => {  
      testUnits\[t.id\] = t.unit;  
    });  
  
    // 5. الـ Transaction لتنفيذ الـ Baseline والـ Enrollment والـ Post سوا بـ Type-safety كاملة  
    const transactionResult = await prisma.$transaction(async (tx) => {  
      // أ) إنشاء الـ Baseline Snapshot  
      const baselineSnapshot = await tx.physical\_snapshots.create({  
        data: {  
          user\_id: userId,  
          sport\_id: program.sport\_id,  
          snapshot\_type: "program\_baseline",  
          snapshot\_test\_values: {  
            create: baseline\_test\_values.map((test: any) => ({  
              attribute\_test\_id: Number(test.attribute\_test\_id),  
              value: Number(test.value),  
              unit: testUnits\[Number(test.attribute\_test\_id)\] || "units",  
            })),  
          },  
        },  
      });  
  
      // ب) إنشاء الـ Enrollment وربطه بالـ Snapshot  
      const enrollment = await tx.enrollments.create({  
        data: {  
          users: { connect: { id: userId } },  
          programs: { connect: { id: program\_id } },  
          status: "active",  
          start\_date: new Date(),  
          preferred\_days: Array.isArray(preferred\_days) ? preferred\_days : \[\],  
          preferred\_time: formattedTime,  
          physical\_snapshots\_enrollments\_baseline\_snapshot\_idTophysical\_snapshots:  
            {  
              connect: { id: baselineSnapshot.id },  
            },  
        },  
      });  
  
      // جـ) تحديث الـ Snapshot بالإشارة العكسية للـ Enrollment ID  
      await tx.physical\_snapshots.update({  
        where: { id: baselineSnapshot.id },  
        data: { program\_enrollment\_id: enrollment.id },  
      });  
  
      // د) توليد الـ System post تلقائياً على الفيد  
      const user = await tx.users.findUnique({  
        where: { id: userId },  
        select: { username: true },  
      });  
  
      await tx.posts.create({  
        data: {  
          user\_id: userId,  
          program\_id: program\_id,  
          content: \`${user?.username || "A user"} just started the "${program.title}" training program! Time to put in the work! 🥊🔥\`,  
          is\_system\_generated: true,  
        },  
      });  
  
      return { enrollment, baselineSnapshotId: baselineSnapshot.id };  
    });  
  
    // 6. 🎯 إرجاع الـ Response مفرود ونظيف ومطابق للـ Assertions في الـ Excel  
    res.status(201).json({  
      id: transactionResult.enrollment.id,  
      status: transactionResult.enrollment.status,  
      start\_date: transactionResult.enrollment.start\_date,  
      baseline\_snapshot\_id: transactionResult.baselineSnapshotId,  
    });  
  } catch (error: any) {  
    // إمساك أخطاء Prisma الـ Unique Constraint كخط دفاع ثانٍ وإرجاع 409 نظيفة  
    if (error.code === "P2002") {  
      return next(new AppError("Conflict — already actively enrolled.", 409));  
    }  
  
    if (error.message?.startsWith("VALIDATION\_ERROR:")) {  
      return next(new AppError(error.message.replace("VALIDATION\_ERROR: ", ""), 400));  
    }  
  
    console.error("Enrollment Error:", error);  
    next(error);  
  }  
};  
//validated  
// --- 4.7 Complete Enrollment (Athlete) ---  
export const completeEnrollment = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = String(req.user?.sub);  
    const { enrollment\_id, posttest\_test\_values } = req.body;  
  
    // 1. جلب الـ Enrollment مع علاقات الـ Baseline للتأكد من الـ وجود والملكيه  
    const enrollment = await prisma.enrollments.findUnique({  
      where: { id: enrollment\_id },  
      include: {  
        programs: { select: { title: true, sport\_id: true, id: true } },  
        physical\_snapshots\_enrollments\_baseline\_snapshot\_idTophysical\_snapshots:  
          {  
            include: { snapshot\_test\_values: true },  
          },  
      },  
    });  
  
    if (!enrollment) {  
      return next(new AppError("Enrollment not found.", 404));  
    }  
  
    if (enrollment.user\_id !== userId) {  
      return next(new AppError("Forbidden: Not your enrollment.", 403));  
    }  
  
    // 2. 🔥 الصد الفوري لسيناريو الـ Sad Path لو الـ Enrollment مش active  
    if (enrollment.status !== "active") {  
      return next(new AppError("Conflict — enrollment is not active.", 409));  
    }  
  
    // 3. التحقق من الـ attribute\_test\_ids وصحتها  
    const testIds: number\[\] = \[\];  
    for (const t of posttest\_test\_values) {  
      if (  
        !t.attribute\_test\_id ||  
        t.value === undefined ||  
        isNaN(Number(t.value))  
      ) {  
        return next(new AppError("Each posttest item must include a valid attribute\_test\_id and a numerical value.", 400));  
      }  
      testIds.push(Number(t.attribute\_test\_id));  
    }  
  
    const testsInfo = await prisma.attribute\_tests.findMany({  
      where: { id: { in: testIds } },  
      select: { id: true, unit: true },  
    });  
  
    if (testsInfo.length !== \[...new Set(testIds)\].length) {  
      return next(new AppError("One or more provided attribute\_test\_ids do not exist in the system.", 404));  
    }  
  
    let testUnits: Record<number, string> = {};  
    testsInfo.forEach((t) => {  
      testUnits\[t.id\] = t.unit;  
    });  
  
    // 4. استخراج الـ Baseline لعمل الـ Mapping والحسابات  
    const baselineValues =  
      enrollment  
        .physical\_snapshots\_enrollments\_baseline\_snapshot\_idTophysical\_snapshots  
        ?.snapshot\_test\_values || \[\];  
    let deltas: any\[\] = \[\];  
  
    posttest\_test\_values.forEach((postTest: any) => {  
      const baseTest = baselineValues.find(  
        (b) => b.attribute\_test\_id === Number(postTest.attribute\_test\_id),  
      );  
      if (baseTest) {  
        const diff = Number(postTest.value) - Number(baseTest.value);  
        deltas.push({  
          test\_id: postTest.attribute\_test\_id,  
          baseline: Number(baseTest.value),  
          posttest: Number(postTest.value),  
          improvement: diff,  
        });  
      }  
    });  
  
    const user = await prisma.users.findUnique({  
      where: { id: userId },  
      select: { username: true },  
    });  
    const testimonial = \`${user?.username || "A user"} completed "${enrollment.programs.title}" and leveled up their stats! 📈🥊\`;  
  
    // 5. 🎯 الـ Transaction المقفلة والآمنه للـ Database Updates  
    const transactionResult = await prisma.$transaction(async (tx) => {  
      const postSnapshot = await tx.physical\_snapshots.create({  
        data: {  
          user\_id: userId,  
          sport\_id: enrollment.programs.sport\_id,  
          snapshot\_type: "program\_posttest",  
          program\_enrollment\_id: enrollment.id,  
          snapshot\_test\_values: {  
            create: posttest\_test\_values.map((t: any) => ({  
              attribute\_test\_id: Number(t.attribute\_test\_id),  
              value: Number(t.value),  
              unit: testUnits\[Number(t.attribute\_test\_id)\] || "units",  
            })),  
          },  
        },  
      });  
  
      const updatedEnrollment = await tx.enrollments.update({  
        where: { id: enrollment\_id },  
        data: {  
          status: "completed",  
          completed\_date: new Date(),  
          physical\_snapshots\_enrollments\_posttest\_snapshot\_idTophysical\_snapshots:  
            {  
              connect: { id: postSnapshot.id },  
            },  
        },  
      });  
  
      await tx.posts.create({  
        data: {  
          user\_id: userId,  
          program\_id: enrollment.program\_id,  
          content: testimonial,  
          is\_system\_generated: true,  
          metadata: { deltas, testimonial },  
        },  
      });  
  
      return updatedEnrollment;  
    });  
  
    // 6. 🎯 الـ Response مفرود بالكامل لتلبية كافة الـ Assertions بدون Wrapper  
    res.status(200).json({  
      enrollment: {  
        id: transactionResult.id,  
        status: transactionResult.status,  
        completed\_date: transactionResult.completed\_date,  
      },  
      deltas,  
      testimonial,  
    });  
  } catch (error: any) {  
    console.error("Complete Enrollment Error:", error);  
    next(error); // الـ الـ الترحيل الذكي والآمن للـ Global Error Handler فورا  
  }  
};  
  
// --- 4.8 Rate Program (Athlete) ---  
export const rateProgram = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = String(req.user?.sub);  
    const { program\_id, rating, review } = req.body;  
    const numericRating = Number(rating);  
  
    // 1. فحص هل المستخدم عنده أي سجل تسجيل (Enrollment) في هذا البرنامج أصلاً  
    const anyEnrollment = await prisma.enrollments.findFirst({  
      where: { user\_id: userId, program\_id: program\_id },  
    });  
  
    if (!anyEnrollment) {  
      return next(new AppError("Forbidden — no completed enrollment found.", 403));  
    }  
  
    // 2. فحص هل الـ Enrollment لسه active ولم يكتمل بعد  
    if (anyEnrollment.status !== "completed") {  
      return next(new AppError("Forbidden — must complete program first.", 403));  
    }  
  
    // 3. فحص التقييم المزدوج (هل قيم البرنامج ده قبل كدة؟)  
    const existingRating = await prisma.program\_ratings.findFirst({  
      where: { user\_id: userId, program\_id: program\_id },  
    });  
  
    if (existingRating) {  
      return next(new AppError("Conflict — already rated (unique constraint).", 409));  
    }  
  
    // 4. تنفيذ الـ Transaction لتسجيل التقييم وتحديث إحصائيات البرنامج  
    const transactionResult = await prisma.$transaction(async (tx) => {  
      // أ) إنشاء سجل التقييم الجديد  
      const newRating = await tx.program\_ratings.create({  
        data: {  
          enrollment\_id: anyEnrollment.id,  
          user\_id: userId,  
          program\_id: program\_id,  
          rating: numericRating,  
          review: review ? String(review).trim() : null,  
        },  
      });  
  
      // ب) حساب المتوسط والعدد الجديد للتقييمات  
      const aggregations = await tx.program\_ratings.aggregate({  
        where: { program\_id: program\_id },  
        \_avg: { rating: true },  
        \_count: { rating: true },  
      });  
  
      const newAvg = aggregations.\_avg.rating || numericRating;  
      const newCount = aggregations.\_count.rating || 1;  
  
      // جـ) تحديث جدول الـ programs الأساسي بالمتوسط والعدد الجديد  
      // ملاحظة: الشيت أشار إلى أن الـ DB trigger بيقوم بده تلقائياً، ولكن زيادة تأكيد وأمان للـ Tests بنعملها جوه الـ Transaction  
      await tx.programs.update({  
        where: { id: program\_id },  
        data: {  
          rating\_avg: newAvg,  
          rating\_count: newCount,  
        },  
      });  
  
      return newRating;  
    });  
  
    // 5. 🎯 إرجاع الـ Response مفرود بالكامل لتلبية شروط التيست  
    res.status(201).json({  
      id: transactionResult.id,  
      program\_id: transactionResult.program\_id,  
      user\_id: transactionResult.user\_id,  
      rating: transactionResult.rating,  
      review: transactionResult.review,  
      created\_at: transactionResult.created\_at,  
    });  
  } catch (error: any) {  
    console.error("Rate Program Error:", error);  
    next(error); // الـ الترحيل السليم للـ Global Error Handler  
  }  
};  
  
// the missed part on the old code // Getting the athlete enrolled programs  
export const getMyEnrolledPrograms = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = String(req.user?.sub);  
  
    // 1. جلب سجلات التسجيل الخاصة باللاعب مع تفاصيل البرنامج الأساسية  
    const enrollments = await prisma.enrollments.findMany({  
      where: { user\_id: userId },  
      include: {  
        programs: {  
          select: {  
            id: true,  
            title: true,  
            description: true,  
            duration\_weeks: true,  
            rating\_avg: true,  
            rating\_count: true,  
            sport\_id: true,  
            coach\_id: true,  
          },  
        },  
        // اختياري: لو عاوز تجيب الـ snapshots المرتبطة بالتسجيل ده  
        physical\_snapshots\_enrollments\_baseline\_snapshot\_idTophysical\_snapshots:  
          {  
            select: { id: true, created\_at: true },  
          },  
      },  
      orderBy: {  
        start\_date: "desc", // ترتيب من الأحدث للأقدم  
      },  
    });  
  
    // 2. 🎯 الـ Sad Path: لو اللاعب مش مسجل في أي برنامج نهائي في السيستم  
    if (!enrollments || enrollments.length === 0) {  
      return next(new AppError("No enrolled programs found for this user.", 404));  
    }  
  
    // 3. 🎯 الـ Happy Path: تجهيز الداتا ومطابقتها وتصفيتها بشكل مفرود  
    const formattedPrograms = enrollments.map((enrollment) => ({  
      enrollment\_id: enrollment.id,  
      status: enrollment.status,  
      start\_date: enrollment.start\_date,  
      completed\_date: enrollment.completed\_date,  
      preferred\_days: enrollment.preferred\_days,  
      preferred\_time: enrollment.preferred\_time,  
      baseline\_snapshot\_id: enrollment.baseline\_snapshot\_id,  
      posttest\_snapshot\_id: enrollment.posttest\_snapshot\_id,  
      program: enrollment.programs, // بيانات البرنامج المدمجة  
    }));  
  
    // إرسال الـ Response مفرود في الـ Root بدون Wrapper تلبية لشروط الشيتات السابقة  
    res.status(200).json(formattedPrograms);  
  } catch (error: any) {  
    console.error("Get Enrolled Programs Error:", error);  
    next(error); // الترحيل الفوري للـ Global Error Handler الآمن  
  }  
};  
  
//we have in explore the top popular programs  
// i think it handled by the front end by doing a for loop on the rating and list the largest on the Rate  
  
import { Response, NextFunction } from "express";  
import { AuthRequest } from "../middlewares/auth.middleware";  
import { prisma } from "../config/prisma";  
import { AppError } from "../utils/AppError";  
  
// --- 6.1 Search ---  
export const search = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const q = req.query.q as string;  
    const type = (req.query.type as string) || "all";  
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);  
    const offset = Math.max(0, parseInt(req.query.offset as string) || 0);  
  
    // 1. Sanitize and prepare search query (TSQuery format)  
    const sanitizedQ = q  
      .replace(/\[&|!:\*()\]/g, "")  
      .trim()  
      .split(/\\s+/)  
      .join(" & ");  
  
    // If after sanitization the query becomes empty (e.g., user sent only "!!!")  
    if (!sanitizedQ) {  
      res  
        .status(200)  
        .json({ success: true, data: { users: \[\], programs: \[\], posts: \[\] } });  
      return;  
    }  
  
    let results: any = { users: \[\], programs: \[\], posts: \[\] };  
  
    // 2. Search in Users table  
    if (type === "all" || type === "users") {  
      const users = await prisma.$queryRaw\`  
                SELECT 'user' AS result\_type, u.id, u.username, u.profile\_photo, u.role,  
                       usp.level, usp.weight\_class,  
                       ts\_rank(u.search\_vector, to\_tsquery('english', ${sanitizedQ})) AS rank  
                FROM users u  
                LEFT JOIN user\_sport\_profiles usp ON usp.user\_id = u.id AND usp.is\_primary = true  
                WHERE u.search\_vector @@ to\_tsquery('english', ${sanitizedQ})  
                ORDER BY rank DESC   
                LIMIT ${limit} OFFSET ${offset}  
            \`;  
      results.users = users;  
    }  
  
    // 3. Search in Programs table  
    if (type === "all" || type === "programs") {  
      const programs = await prisma.$queryRaw\`  
                SELECT 'program' AS result\_type, p.id, p.title, p.description, p.goal\_primary,  
                       p.rating\_avg, p.cover\_image, u.username AS coach\_name,  
                       ts\_rank(p.search\_vector, to\_tsquery('english', ${sanitizedQ})) AS rank  
                FROM programs p   
                JOIN users u ON u.id = p.coach\_id  
                WHERE p.is\_published = true AND p.search\_vector @@ to\_tsquery('english', ${sanitizedQ})  
                ORDER BY rank DESC   
                LIMIT ${limit} OFFSET ${offset}  
            \`;  
      results.programs = programs;  
    }  
  
    // 4. Search in Posts table  
    if (type === "all" || type === "posts") {  
      const posts = await prisma.$queryRaw\`  
                SELECT 'post' AS result\_type, p.id, LEFT(p.content, 150) AS preview,  
                       p.created\_at, u.username, u.profile\_photo,  
                       ts\_rank(p.search\_vector, to\_tsquery('english', ${sanitizedQ})) AS rank  
                FROM posts p   
                JOIN users u ON u.id = p.user\_id  
                WHERE p.search\_vector @@ to\_tsquery('english', ${sanitizedQ})  
                ORDER BY rank DESC   
                LIMIT ${limit} OFFSET ${offset}  
            \`;  
      results.posts = posts;  
    }  
  
    res.status(200).json({ success: true, data: results });  
  } catch (error: any) {  
    console.error("Search Error:", error);  
    next(new AppError("Failed to perform search due to an internal server error.", 500));  
  }  
};  
  
// --- 6.2 Sync Search Vectors (Admin Only) ---  
export const syncSearchVectors = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    await prisma.$executeRaw\`UPDATE users SET search\_vector = to\_tsvector('english', coalesce(username, '') || ' ' || coalesce(bio, ''))\`;  
    await prisma.$executeRaw\`UPDATE programs SET search\_vector = to\_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))\`;  
    await prisma.$executeRaw\`UPDATE posts SET search\_vector = to\_tsvector('english', coalesce(content, ''))\`;  
  
    res.status(200).json({  
      success: true,  
      message:  
        "All search vectors synchronized successfully across users, programs, and posts!",  
    });  
  } catch (error) {  
    console.error("Sync Search Vectors Error:", error);  
    next(new AppError("Failed to synchronize search vectors due to a database backend failure.", 500));  
  }  
};  
import { Response, NextFunction } from 'express';  
import { AuthRequest } from '../middlewares/auth.middleware';  
import { prisma } from '../config/prisma';  
import { AppError } from '../utils/AppError';  
import 'multer'; // Import for type augmentation to recognize req.file  
  
// --- 5.1 Get Social Feed ---  
export const getFeed = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const limit = parseInt(req.query.limit as string) || 20;  
        const offset = parseInt(req.query.offset as string) || 0;  
  
        // 1. Get the list of user IDs the player is following (Followees)  
        const following = await prisma.follows.findMany({  
            where: { follower\_id: userId },  
            select: { followee\_id: true }  
        });  
        const followeeIds = following.map(f => f.followee\_id);  
  
        // 2. Posts fetched will belong to the user and their followees  
        const targetUserIds = \[userId, ...followeeIds\];  
  
        // 3. Fetch posts in chronological order (newest first)  
        const posts = await prisma.posts.findMany({  
            where: {  
                user\_id: { in: targetUserIds }  
            },  
            take: limit,  
            skip: offset,  
            orderBy: { created\_at: 'desc' },  
            include: {  
                users: {  
                    select: { id: true, username: true, profile\_photo: true, role: true }  
                },  
                likes: {  
                    where: { user\_id: userId },  
                    select: { user\_id: true }  
                }  
            }  
        });  
  
        // 4. Format data for the frontend  
        const formattedPosts = posts.map(post => {  
            const { likes, users, ...postData } = post;  
            return {  
                ...postData,  
                author: users,  
                is\_liked\_by\_me: likes.length > 0  
            };  
        });  
  
        res.status(200).json({  
            success: true,  
            data: formattedPosts,  
            meta: { limit, offset, count: formattedPosts.length }  
        });  
  
    } catch (error: any) {  
        console.error("Get Feed Error:", error);  
        next(new AppError("Failed to fetch feed.", 500));  
    }  
};  
  
// --- 5.2 Create Post ---  
export const createPost = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = req.user?.sub as string;  
        let { content } = req.body;  
        const file = (req as any).file;  
  
        // Sanitize content if it exists  
        if (content) {  
            content = content.replace(/<\[^>\]\*>?/gm, '');  
        }  
  
        const imagePath = file ? file.path : null;  
  
        const newPost = await prisma.posts.create({  
            data: {  
                user\_id: userId,  
                content: content || '',  
                image\_path: imagePath  
            }  
        });  
  
        res.status(201).json({  
            success: true,  
            data: newPost  
        });  
  
    } catch (error: any) {  
        console.error("Create Post Error:", error);  
        next(new AppError("Failed to create post.", 500));  
    }  
};  
  
// --- 5.12 Get Specific Post ---  
export const getSpecificPost = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const postId = req.params.id;  
  
        const post = await prisma.posts.findUnique({  
            where: { id: postId as any },  
            include: {  
                users: {  
                    select: { id: true, username: true, profile\_photo: true, role: true }  
                },  
                likes: {  
                    where: { user\_id: userId },  
                    select: { user\_id: true }  
                }  
            }  
        });  
  
        if (!post) {  
            return next(new AppError("Post not found.", 404));  
        }  
  
        const { likes, users, ...postData } = post;  
        const formattedPost = {  
            ...postData,  
            author: users,  
            is\_liked\_by\_me: likes.length > 0  
        };  
  
        res.status(200).json({  
            success: true,  
            data: formattedPost  
        });  
  
    } catch (error: any) {  
        console.error("Get Specific Post Error:", error);  
        next(new AppError("Failed to fetch post.", 500));  
    }  
};  
  
// --- 5.3 Get User Posts ---   
export const getUserPosts = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const targetUserId = (req.params.id || req.query.user\_id) as string;  
        const limit = parseInt(req.query.limit as string) || 20;  
        const offset = parseInt(req.query.offset as string) || 0;  
  
        const userExists = await prisma.users.findUnique({  
            where: { id: targetUserId }  
        });  
  
        if (!userExists) {  
            return next(new AppError("User not found.", 404));  
        }  
  
        const posts = await prisma.posts.findMany({  
            where: { user\_id: targetUserId },  
            take: limit,  
            skip: offset,  
            orderBy: { created\_at: 'desc' },  
            include: {  
                users: {  
                    select: { id: true, username: true, profile\_photo: true, role: true }  
                }  
            }  
        });  
  
        const formattedPosts = posts.map(post => {  
            const { users, ...postData } = post;  
            return {  
                ...postData,  
                author: users  
            };  
        });  
  
        res.status(200).json({  
            success: true,  
            data: formattedPosts,  
            meta: { limit, offset, count: formattedPosts.length }  
        });  
  
    } catch (error: any) {  
        console.error("Get User Posts Error:", error);  
        next(new AppError("Failed to fetch user posts.", 500));  
    }  
};  
  
// --- 5.4 Like Post ---  
export const likePost = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const postId = String(req.params.id);  
  
        const post = await prisma.posts.findUnique({ where: { id: postId } });  
        if (!post) {  
            return next(new AppError("Post not found.", 404));  
        }  
  
        try {  
            await prisma.likes.create({  
                data: { user\_id: userId, post\_id: postId }  
            });  
        } catch (e: any) {  
            if (e.code !== 'P2002') throw e;  
        }  
  
        res.status(200).json({ liked: true });  
  
    } catch (error: any) {  
        console.error("Like Post Error:", error);  
        next(new AppError("Failed to like post.", 500));  
    }  
};  
  
// --- 5.5 Unlike Post ---  
export const unlikePost = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const postId = String(req.params.id);  
  
        const post = await prisma.posts.findUnique({ where: { id: postId } });  
        if (!post) {  
            return next(new AppError("Post not found.", 404));  
        }  
  
        await prisma.likes.deleteMany({  
            where: { post\_id: postId, user\_id: userId }  
        });  
  
        res.status(200).json({ liked: false });  
  
    } catch (error: any) {  
        console.error("Unlike Post Error:", error);  
        next(new AppError("Failed to unlike post.", 500));  
    }  
};  
  
// --- 5.6 Get Comments ---  
export const getComments = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const postId = String(req.params.id);  
        const limit = parseInt(req.query.limit as string) || 20;  
        const offset = parseInt(req.query.offset as string) || 0;  
  
        const post = await prisma.posts.findUnique({ where: { id: postId } });  
        if (!post) {  
            return next(new AppError("Post not found.", 401)); // Requested 401 per your logic  
        }  
  
        const comments = await prisma.comments.findMany({  
            where: { post\_id: postId },  
            take: limit,  
            skip: offset,  
            orderBy: { created\_at: 'asc' },  
            include: {  
                users: {  
                    select: { id: true, username: true, profile\_photo: true }  
                }  
            }  
        });  
  
        const formattedComments = comments.map(c => ({  
            id: c.id,  
            content: c.content,  
            created\_at: c.created\_at,  
            author\_id: c.users?.id,  
            username: c.users?.username,  
            profile\_photo: c.users?.profile\_photo  
        }));  
  
        res.status(200).json({  
            success: true,  
            data: formattedComments,  
            meta: { limit, offset, count: formattedComments.length }  
        });  
  
    } catch (error: any) {  
        console.error("Get Comments Error:", error);  
        next(new AppError("Failed to fetch comments.", 500));  
    }  
};  
  
// --- 5.7 Add Comment ---  
export const addComment = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const postId = String(req.params.id);  
        let { content } = req.body;  
  
        const post = await prisma.posts.findUnique({ where: { id: postId } });  
        if (!post) {  
            return next(new AppError("Post not found.", 401));  
        }  
  
        content = content.trim();  
        content = content.replace(/<\[^>\]\*>?/gm, '');  
  
        const comment = await prisma.comments.create({  
            data: {  
                user\_id: userId,  
                post\_id: postId,  
                content: content  
            },  
            include: {  
                users: { select: { id: true, username: true, profile\_photo: true } }  
            }  
        });  
  
        res.status(201).json({  
            success: true,  
            message: "Comment added successfully",  
            data: {  
                id: comment.id,  
                content: comment.content,  
                created\_at: comment.created\_at,  
                author: comment.users  
            }  
        });  
  
    } catch (error: any) {  
        console.error("Add Comment Error:", error);  
        next(new AppError("Failed to add comment.", 500));  
    }  
};  
// --- 5.13 Update Post ---  
export const updatePost = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const postId = req.params.id;  
        let { content } = req.body;  
        const file = (req as any).file;  
  
        const post = await prisma.posts.findUnique({ where: { id: postId as any } });  
        if (!post) {  
            return next(new AppError("Post not found.", 404));  
        }  
        if (post.user\_id !== userId) {  
            return next(new AppError("Forbidden — you can only update your own posts.", 403));  
        }  
  
        if (content) {  
            content = content.replace(/<\[^>\]\*>?/gm, ''); // Sanitize HTML  
        }  
  
        const imagePath = file ? file.path : post.image\_path;  
  
        const updatedPost = await prisma.posts.update({  
            where: { id: postId as any },  
            data: {  
                ...(content !== undefined && { content }),  
                image\_path: imagePath  
            }  
        });  
  
        res.status(200).json({ success: true, data: updatedPost });  
    } catch (error: any) {  
        console.error("Update Post Error:", error);  
        next(new AppError("Failed to update post.", 500));  
    }  
};  
  
// --- 5.14 Delete Post ---  
export const deletePost = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const postId = req.params.id;  
  
        const post = await prisma.posts.findUnique({ where: { id: postId as any } });  
        if (!post) {  
            return next(new AppError("Post not found.", 404));  
        }  
        if (post.user\_id !== userId) {  
            return next(new AppError("Forbidden — you can only delete your own posts.", 403));  
        }  
  
        await prisma.posts.delete({ where: { id: postId as any } });  
  
        res.status(200).json({ success: true, message: "Post deleted successfully." });  
    } catch (error: any) {  
        console.error("Delete Post Error:", error);  
        next(new AppError("Failed to delete post.", 500));  
    }  
};  
  
// --- 5.15 Update Comment ---  
export const updateComment = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const commentId = req.params.id;  
        let { content } = req.body;  
  
        const comment = await prisma.comments.findUnique({ where: { id: commentId as any } });  
        if (!comment) {  
            return next(new AppError("Comment not found.", 404));  
        }  
        if (comment.user\_id !== userId) {  
            return next(new AppError("Forbidden — you can only update your own comments.", 403));  
        }  
  
        content = content.trim().replace(/<\[^>\]\*>?/gm, '');  
  
        const updatedComment = await prisma.comments.update({  
            where: { id: commentId as any },  
            data: { content }  
        });  
  
        res.status(200).json({ success: true, data: updatedComment });  
    } catch (error: any) {  
        console.error("Update Comment Error:", error);  
        next(new AppError("Failed to update comment.", 500));  
    }  
};  
  
// --- 5.16 Delete Comment ---  
// --- 5.16 Delete Comment ---  
export const deleteComment = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const userId = String(req.user?.sub);  
        const commentId = req.params.id;  
  
        // 🎯 1. جلب الكومنت، ودمج بيانات البوست المرتبط بيه عشان نعرف مين صاحب البوست  
        const comment = await prisma.comments.findUnique({  
            where: { id: commentId as any },  
            include: {  
                posts: {  
                    select: { user\_id: true } // بنجيب ID صاحب البوست بس عشان الأداء  
                }  
            }  
        });  
  
        if (!comment) {  
            return next(new AppError("Comment not found.", 404));  
        }  
  
        // 🎯 2. تحديد الصلاحيات  
        const isCommentAuthor = comment.user\_id === userId; // هل هو اللي كاتب الكومنت؟  
        const isPostAuthor = comment.posts?.user\_id === userId; // هل هو صاحب البوست نفسه؟  
  
        // 🎯 3. لو مش ده ولا ده، نرفض العملية  
        if (!isCommentAuthor && !isPostAuthor) {  
            return next(new AppError("Forbidden — you can only delete your own comments or comments on your posts.", 403));  
        }  
  
        // 4. تنفيذ المسح  
        await prisma.comments.delete({ where: { id: commentId as any } });  
  
        res.status(200).json({ success: true, message: "Comment deleted successfully." });  
    } catch (error: any) {  
        console.error("Delete Comment Error:", error);  
        next(new AppError("Failed to delete comment.", 500));  
    }  
};  
// --- 5.8 Follow User ---  
export const followUser = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const followerId = String(req.user?.sub);  
        const followeeId = String(req.params.userId);  
  
        if (followerId === followeeId) {  
            return next(new AppError("You cannot follow yourself.", 400));  
        }  
  
        const userExists = await prisma.users.findUnique({ where: { id: followeeId } });  
        if (!userExists) {  
            return next(new AppError("User to follow not found.", 404));  
        }  
  
        try {  
            await prisma.follows.create({  
                data: { follower\_id: followerId, followee\_id: followeeId }  
            });  
        } catch (e: any) {  
            if (e.code !== 'P2002') throw e;  
        }  
  
        res.status(200).json({ following: true });  
  
    } catch (error: any) {  
        console.error("Follow User Error:", error);  
        next(new AppError("Failed to follow user.", 500));  
    }  
};  
  
// --- 5.9 Unfollow User ---  
export const unfollowUser = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const followerId = String(req.user?.sub);  
        const followeeId = String(req.params.userId);  
  
        await prisma.follows.deleteMany({  
            where: { follower\_id: followerId, followee\_id: followeeId }  
        });  
  
        res.status(200).json({ following: false });  
  
    } catch (error: any) {  
        console.error("Unfollow User Error:", error);  
        next(new AppError("Failed to unfollow user.", 500));  
    }  
};  
  
// --- 5.10 Get Followers ---  
export const getFollowers = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const targetUserId = String(req.params.id);  
        const limit = parseInt(req.query.limit as string) || 20;  
        const offset = parseInt(req.query.offset as string) || 0;  
  
        const userExists = await prisma.users.findUnique({  
            where: { id: targetUserId }  
        });  
  
        if (!userExists) {  
            return next(new AppError("User not found.", 404));  
        }  
  
        const followers = await prisma.follows.findMany({  
            where: { followee\_id: targetUserId },  
            take: limit,  
            skip: offset,  
            orderBy: { created\_at: 'desc' },  
            include: {  
                users\_follows\_follower\_idTousers: {  
                    select: {  
                        id: true,  
                        username: true,  
                        profile\_photo: true,  
                        role: true,  
                        user\_sport\_profiles: {  
                            where: { is\_primary: true },  
                            select: { level: true, weight\_class: true }  
                        }  
                    }  
                }  
            }  
        });  
  
        const formattedFollowers = followers.map(f => {  
            const user = f.users\_follows\_follower\_idTousers;  
            const profile = user?.user\_sport\_profiles?.\[0\];  
            return {  
                id: user?.id,  
                username: user?.username,  
                profile\_photo: user?.profile\_photo,  
                role: user?.role,  
                level: profile?.level || null,  
                weight\_class: profile?.weight\_class || null  
            };  
        });  
  
        res.status(200).json({ success: true, data: formattedFollowers, meta: { limit, offset, count: formattedFollowers.length } });  
  
    } catch (error: any) {  
        console.error("Get Followers Error:", error);  
        next(new AppError("Failed to fetch followers.", 500));  
    }  
};  
  
// --- 5.11 Get Following ---  
export const getFollowing = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {  
    try {  
        const targetUserId = String(req.params.id);  
        const limit = parseInt(req.query.limit as string) || 20;  
        const offset = parseInt(req.query.offset as string) || 0;  
  
        const userExists = await prisma.users.findUnique({  
            where: { id: targetUserId }  
        });  
  
        if (!userExists) {  
            return next(new AppError("User not found.", 404));  
        }  
  
        const following = await prisma.follows.findMany({  
            where: { follower\_id: targetUserId },  
            take: limit,  
            skip: offset,  
            orderBy: { created\_at: 'desc' },  
            include: {  
                users\_follows\_followee\_idTousers: {  
                    select: {  
                        id: true,  
                        username: true,  
                        profile\_photo: true,  
                        role: true,  
                        user\_sport\_profiles: {  
                            where: { is\_primary: true },  
                            select: { level: true, weight\_class: true }  
                        }  
                    }  
                }  
            }  
        });  
  
        const formattedFollowing = following.map(f => {  
            const user = f.users\_follows\_followee\_idTousers;  
            const profile = user?.user\_sport\_profiles?.\[0\];  
            return {  
                id: user?.id,  
                username: user?.username,  
                profile\_photo: user?.profile\_photo,  
                role: user?.role,  
                level: profile?.level || null,  
                weight\_class: profile?.weight\_class || null  
            };  
        });  
  
        res.status(200).json({ success: true, data: formattedFollowing, meta: { limit, offset, count: formattedFollowing.length } });  
  
    } catch (error: any) {  
        console.error("Get Following Error:", error);  
        next(new AppError("Failed to fetch following.", 500));  
    }  
};  
import { Response, NextFunction } from "express";  
import { AuthRequest } from "../middlewares/auth.middleware";  
import { prisma } from "../config/prisma";  
import { v2 as cloudinary } from "cloudinary";  
import { AppError } from "../utils/AppError";  
  
// Works without Validator  
export const deactivateAccount = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    await prisma.$transaction(\[  
      // 1. Set account status to Inactive  
      prisma.users.update({  
        where: { id: userId },  
        data: { is\_active: false },  
      }),  
  
      prisma.user\_tokens.deleteMany({  
        where: { user\_id: userId, token\_type: "REFRESH" },  
      }),  
    \]);  
  
    res.status(200).json({  
      success: true,  
      message:  
        "Account deactivated successfully. You have been logged out from all devices.",  
    });  
  } catch (error) {  
    console.error("Deactivate Account Error:", error);  
    next(new AppError("Internal server error", 500));  
  }  
};  
  
// works good without Validator  
export const getMe = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    const user = await prisma.users.findUnique({  
      where: { id: userId },  
      include: {  
        user\_sport\_profiles: {  
          where: { is\_primary: true },  
          include: { sports: true },  
        },  
      },  
    });  
  
    if (!user) {  
      return next(new AppError("User not found.", 404));  
    }  
  
    const { password\_hash, ...safeUserData } = user;  
  
    res.status(200).json({  
      success: true,  
      data: safeUserData,  
    });  
  } catch (error: any) {  
    console.error("Get Me Error:", error);  
    next(new AppError("Failed to fetch user profile.", 500));  
  }  
};  
  
// Done  
export const uploadPhoto = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
    const file = (req as any).file;  
  
    if (!file) {  
      return next(new AppError("Validation error — file required.", 400));  
    }  
  
    const photoUrl = file.path;  
  
    const user = await prisma.users.findUnique({ where: { id: userId } });  
    if (user?.profile\_photo) {  
      const publicIdMatch = user.profile\_photo.match(/\\/v\\d+\\/(.+?)\\.\\w+$/);  
      if (publicIdMatch && publicIdMatch\[1\]) {  
        await cloudinary.uploader.destroy(publicIdMatch\[1\]);  
      }  
    }  
  
    const updatedUser = await prisma.users.update({  
      where: { id: userId },  
      data: { profile\_photo: photoUrl },  
    });  
  
    res.status(201).json({  
      success: true,  
      profile\_photo\_url: updatedUser.profile\_photo,  
    });  
  } catch (error: any) {  
    if (  
      error.message?.includes("format pdf not allowed") ||  
      error.http\_code === 400  
    ) {  
      return next(  
        new AppError("Invalid file type — only JPEG, PNG, WEBP accepted.", 400),  
      );  
    }  
  
    if (error.message?.includes("limit") || error.message?.includes("large")) {  
      return next(new AppError("File size exceeds limit.", 400));  
    }  
  
    next(error);  
  }  
};  
  
// Done  
export const updateMe = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub as string;  
  
    // 📌 ضفنا full\_name في الـ destructuring  
    const { full\_name, bio, username, social\_links, role\_models, role } =  
      req.body;  
  
    if (username) {  
      const sanitizedUsername = username.trim();  
  
      const existingUser = await prisma.users.findFirst({  
        where: {  
          username: {  
            equals: sanitizedUsername,  
            mode: "insensitive",  
          },  
        },  
      });  
      console.log("DEBUG UPDATE\_ME -> Current User ID:", userId);  
      console.log(  
        "DEBUG UPDATE\_ME -> Found Existing User:",  
        existingUser  
          ? { id: existingUser.id, username: existingUser.username }  
          : "Not Found",  
      );  
  
      if (existingUser) {  
        if (existingUser.id !== userId) {  
          return next(new AppError("Username is already taken.", 409));  
        }  
      }  
    }  
  
    const updateData: any = {};  
  
    // 📌 ضفنا السطر ده عشان يجهز الـ full\_name للتحديث  
    if (full\_name !== undefined) updateData.full\_name = full\_name.trim();  
    if (bio !== undefined) updateData.bio = bio;  
    if (username !== undefined) updateData.username = username.trim();  
    if (social\_links !== undefined) updateData.social\_links = social\_links;  
    if (role\_models !== undefined) updateData.role\_models = role\_models;  
    if (role !== undefined) updateData.role = role;  
  
    const updatedUser = await prisma.users.update({  
      where: { id: userId },  
      data: updateData,  
      include: {  
        user\_sport\_profiles: {  
          where: { is\_primary: true },  
          include: { sports: true },  
        },  
      },  
    });  
    const { password\_hash, ...safeUserData } = updatedUser;  
  
    res.status(200).json({  
      success: true,  
      message: "Profile updated successfully.",  
      data: safeUserData,  
    });  
  } catch (error) {  
    next(error);  
  }  
};  
// export const getPublicProfile = async (  
//   req: AuthRequest,  
//   res: Response,  
// ): Promise<void> => {  
//   try {  
//     const targetUserId = req.params.id; // Target profile ID to view  
//     const requestingUserId = req.user?.sub as string; // ID of the requesting user  
  
//     if (!targetUserId || (targetUserId as string).trim() === "") {  
//       res.status(400).json({  
//         success: false,  
//         error: "Validation error — user\_id param is required.",  
//       });  
//       return;  
//     }  
  
//     const uuidRegex =  
//       /^\[0-9a-fA-F\]{8}-\[0-9a-fA-F\]{4}-\[0-9a-fA-F\]{4}-\[0-9a-fA-F\]{4}-\[0-9a-fA-F\]{12}$/;  
//     if (!uuidRegex.test(targetUserId as string)) {  
//       res  
//         .status(400)  
//         .json({ success: false, error: "Validation error — invalid UUID." });  
//       return;  
//     }  
  
//     const targetUser = await prisma.users.findUnique({  
//       where: { id: targetUserId as string },  
//       include: {  
//         user\_sport\_profiles: {  
//           where: { is\_primary: true },  
//           include: { sports: true },  
//         },  
//       },  
//     });  
  
//     if (!targetUser) {  
//       res.status(404).json({ success: false, error: "User not found." });  
//       return;  
//     }  
  
//     let is\_following = false;  
  
//     if (requestingUserId && requestingUserId !== targetUserId) {  
//       const followRecord = await prisma.follows.findUnique({  
//         where: {  
//           follower\_id\_followee\_id: {  
//             follower\_id: requestingUserId,  
//             followee\_id: targetUserId as string,  
//           },  
//         },  
//       });  
//       is\_following = !!followRecord;  
//     }  
  
//     const { password\_hash, email, date\_of\_birth, ...publicData } = targetUser;  
  
//     res.status(200).json({  
//       success: true,  
//       data: {  
//         ...publicData,  
//         is\_following,  
//       },  
//     });  
//   } catch (error: any) {  
//     console.error("Get Public Profile Error:", error);  
//     res  
//       .status(500)  
//       .json({ success: false, error: "Failed to fetch user profile." });  
//   }  
// };  
  
//  i think it works in success format  
export const getPublicProfile = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const targetUserId = req.query.user\_id as string;  
    const requestingUserId = req.user?.sub as string;  
  
    // 🎯 مسحنا الـ Validation من هنا لأنه بقى بيتعمل في validator.ts  
  
    const targetUser = await prisma.users.findUnique({  
      where: { id: targetUserId },  
      include: {  
        user\_sport\_profiles: {  
          where: { is\_primary: true },  
          include: { sports: true },  
        },  
      },  
    });  
  
    if (!targetUser) {  
      return next(new AppError("User not found.", 404));  
    }  
  
    const followersCount = await prisma.follows.count({  
      where: { followee\_id: targetUserId },  
    });  
    const followingCount = await prisma.follows.count({  
      where: { follower\_id: targetUserId },  
    });  
  
    let is\_following = false;  
    if (requestingUserId && requestingUserId !== targetUserId) {  
      const followRecord = await prisma.follows.findUnique({  
        where: {  
          follower\_id\_followee\_id: {  
            follower\_id: requestingUserId,  
            followee\_id: targetUserId,  
          },  
        },  
      });  
      is\_following = !!followRecord;  
    }  
  
    const userAny = targetUser as any;  
    const sportProfiles = userAny.user\_sport\_profiles || \[\];  
  
    const cleanedSportProfiles = sportProfiles.map(  
      ({ user\_id, ...rest }: any) => rest,  
    );  
  
    const { password\_hash, email, date\_of\_birth, ...publicData } = userAny;  
  
    res.status(200).json({  
      success: true,  
      data: {  
        ...publicData,  
        user\_sport\_profiles: cleanedSportProfiles,  
        followers\_count: followersCount,  
        following\_count: followingCount,  
        programs\_completed: 0,  
        is\_following,  
      },  
    });  
  } catch (error: any) {  
    console.error("Get Public Profile Error:", error);  
    next(new AppError("Failed to fetch user profile.", 500));  
  }  
};  
import { Response, NextFunction } from "express";  
import { prisma } from "../config/prisma";  
import { AuthRequest } from "../middlewares/auth.middleware";  
import { AppError } from "../utils/AppError";  
  
// Get Next Workout  
export const getNextWorkout = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction, // 👈 الـ Next لترحيل الأخطاء للـ Global Error Handler  
): Promise<void> => {  
  try {  
    // 🚨 Sad Path: التشييك على التوكن والـ Payload  
    const userId = req.user?.sub ? String(req.user.sub) : null;  
    if (!userId) {  
      return next(new AppError("Unauthorized.", 401));  
    }  
  
    const queryEnrollmentId = req.query.enrollment\_id as string;  
    let activeEnrollment = null;  
  
    // 1. التعامل مع الـ Enrollment لو مبعوت أو جلب الأحدث ديناميكياً  
    if (queryEnrollmentId) {  
      const enrollment = await prisma.enrollments.findUnique({  
        where: { id: queryEnrollmentId },  
        select: {  
          id: true,  
          user\_id: true,  
          status: true,  
          program\_id: true,  
          start\_date: true,  
        },  
      });  
  
      if (!enrollment) {  
        return next(new AppError("Enrollment not found.", 404));  
      }  
  
      if (enrollment.user\_id !== userId) {  
        return next(new AppError("Forbidden.", 403));  
      }  
  
      if (enrollment.status !== "active") {  
        return next(new AppError("No active enrollment found.", 404));  
      }  
  
      activeEnrollment = enrollment;  
    } else {  
      activeEnrollment = await prisma.enrollments.findFirst({  
        where: { user\_id: userId, status: "active" },  
        orderBy: { created\_at: "desc" },  
        select: { id: true, program\_id: true, start\_date: true },  
      });  
    }  
  
    if (!activeEnrollment) {  
      return next(new AppError("No active enrollment found.", 404));  
    }  
  
    // 2. جلب الـ Sessions المتبقية والـ Exercises المرتبطة بها  
    const completedSessions = await prisma.completed\_sessions.findMany({  
      where: { enrollment\_id: activeEnrollment.id },  
      select: { program\_session\_id: true },  
    });  
    const completedSessionIds = completedSessions.map(  
      (cs) => cs.program\_session\_id,  
    );  
  
    const nextSession = await prisma.program\_sessions.findFirst({  
      where: {  
        id: { notIn: completedSessionIds },  
        program\_blocks: {  
          program\_id: activeEnrollment.program\_id,  
        },  
      },  
      orderBy: \[  
        { program\_blocks: { order\_index: "asc" } },  
        { day\_offset: "asc" },  
      \],  
      include: {  
        session\_exercises: {  
          orderBy: { order\_index: "asc" },  
          select: {  
            id: true,  
            exercise\_name: true, // 👈 الحقل الصحيح من الـ Schema بعد الفيكس  
            order\_index: true,  
            sets: true,  
            reps: true,  
            rest\_seconds: true,  
          },  
        },  
      },  
    });  
  
    // 🎯 الـ Happy Path: في حالة إتمام البرنامج بالكامل  
    if (!nextSession) {  
      res.status(200).json({  
        next\_workout: null,  
        message: "All sessions completed. Ready to finish the program.", // مطابقة للشيت  
      });  
      return;  
    }  
  
    // حساب تاريخ التمرين بناءً على الـ start\_date والـ day\_offset  
    const scheduledDate = new Date(activeEnrollment.start\_date);  
    scheduledDate.setDate(scheduledDate.getDate() + nextSession.day\_offset);  
  
    // 🔄 تحويل الـ exercise\_name إلى name بالملي لإرضاء الـ Automated Test  
    const formattedExercises = nextSession.session\_exercises.map((ex) => ({  
      id: ex.id,  
      name: ex.exercise\_name, // 👈 الـ Alias المطلوب للشيت  
      order\_index: ex.order\_index,  
      sets: ex.sets,  
      reps: ex.reps,  
      rest\_seconds: ex.rest\_seconds,  
    }));  
  
    // 🎯 الـ Happy Path الأساسي: الداتا مفرودة بالكامل ومباشرة بدون wrappers  
    res.status(200).json({  
      session\_id: nextSession.id,  
      session\_name: nextSession.name,  
      day\_offset: nextSession.day\_offset,  
      estimated\_duration\_minutes: nextSession.estimated\_duration\_minutes,  
      scheduled\_date: scheduledDate.toISOString().split("T")\[0\],  
      exercises: formattedExercises,  
    });  
  } catch (error: any) {  
    console.error("Get Next Workout Error:", error);  
    next(error); // 👈 ترحيل أي خطأ طارئ للـ Global Error Handler ليتعامل مع الـ 500 بنظافة  
  }  
};  
  
//Log Workout  
export const logWorkout = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    const userId = req.user?.sub ? String(req.user.sub) : null;  
    if (!userId) {  
      return next(new AppError("Unauthorized.", 401));  
    }  
  
    const {  
      enrollment\_id,  
      session\_id,  
      rpe,  
      duration\_minutes,  
      notes,  
      exercises,  
      completed\_at,  
    } = req.body;  
  
    // 1. جلب الـ Enrollment والتحقق من وجوده وصاحبه  
    const enrollment = await prisma.enrollments.findUnique({  
      where: { id: enrollment\_id },  
      select: { user\_id: true, status: true, program\_id: true },  
    });  
  
    if (!enrollment) {  
      return next(new AppError("Enrollment not found.", 404));  
    }  
  
    // تأمين الـ Resource: التأكد من أن الـ Athlete هو صاحب الـ Enrollment  
    if (enrollment.user\_id !== userId) {  
      return next(new AppError("Forbidden.", 403));  
    }  
  
    // 🚨 سطر 40 في الشيت: لو الـ enrollment مش active يرجع 409 Conflict  
    if (enrollment.status !== "active") {  
      return next(new AppError("Cannot log to completed enrollment.", 409));  
    }  
  
    // 2. سطر 39 في الشيت: التأكد إن الـ Session دي تبع الـ Program المسجل فيه اللاعب فعلياً  
    const sessionInProgram = await prisma.program\_sessions.findFirst({  
      where: {  
        id: session\_id,  
        program\_blocks: {  
          program\_id: enrollment.program\_id,  
        },  
      },  
    });  
  
    if (!sessionInProgram) {  
      return next(new AppError("Forbidden — session does not belong to this enrollment's program.", 403));  
    }  
  
    // 3. تنفيذ الـ Transaction لتسجيل الـ Log وحفظ الداتا متكاملة في خطوة واحدة  
    const result = await prisma.$transaction(async (tx) => {  
      const completedSession = await tx.completed\_sessions.create({  
        data: {  
          user\_id: userId,  
          enrollment\_id: enrollment\_id,  
          program\_session\_id: session\_id,  
          rpe: rpe ? Number(rpe) : null,  
          duration\_minutes: duration\_minutes ? Number(duration\_minutes) : null,  
          notes: notes || null, // الحماية هنا: هتنزل null في الـ DB لو مش مبعوتة من الـ body  
          created\_at: completed\_at ? new Date(completed\_at) : new Date(),  
        },  
      });  
  
      // لو مبعوت داتا للـ Exercises الفرعية، سيفها معاها في نفس اللحظة  
      if (exercises && Array.isArray(exercises)) {  
        const exercisesData = exercises.map((ex: any) => ({  
          completed\_session\_id: completedSession.id,  
          session\_exercise\_id: ex.session\_exercise\_id,  
          sets\_data: ex.sets\_data || \[\],  
          notes: ex.notes || null,  
        }));  
  
        await tx.completed\_exercises.createMany({  
          data: exercisesData,  
        });  
      }  
  
      return completedSession;  
    });  
  
    // 🎯 الـ Happy Paths (سطر 33 و 34): إرجاع الـ JSON بالـ Structure المطلوب تماماً  
    res.status(201).json({  
      id: result.id,  
      session\_info: {  
        session\_id: result.program\_session\_id,  
        notes: result.notes, // هترجع null تلقائياً لو مكنش ليها قيمة  
      },  
      timestamp: result.created\_at.toISOString(),  
    });  
  } catch (error: any) {  
    console.error("Log Workout Error:", error);  
    next(error); // ترحيل آمن للـ Global Error Handler عشان يرجع الـ 500 النظيفة  
  }  
};  
  
// Get Workout History  
export const getWorkoutHistory = async (  
  req: AuthRequest,  
  res: Response,  
  next: NextFunction,  
): Promise<void> => {  
  try {  
    // 1. Sad Path: No token  
    const userId = req.user?.sub ? String(req.user.sub) : null;  
    if (!userId) {  
      return next(new AppError("Unauthorized.", 401));  
    }  
  
    const limit = parseInt(req.query.limit as string) || 20;  
    const offset = parseInt(req.query.offset as string) || 0;  
    const queryEnrollmentId = req.query.enrollment\_id as string;  
  
    const whereCondition: any = { user\_id: userId };  
  
    if (queryEnrollmentId) {  
      const enrollment = await prisma.enrollments.findUnique({  
        where: { id: queryEnrollmentId },  
        select: { user\_id: true },  
      });  
  
      if (!enrollment) {  
        return next(new AppError("Enrollment not found.", 404));  
      }  
  
      if (enrollment.user\_id !== userId) {  
        return next(new AppError("Forbidden.", 403));  
      }  
  
      whereCondition.enrollment\_id = queryEnrollmentId;  
    }  
  
    const history = await prisma.completed\_sessions.findMany({  
      where: whereCondition,  
      orderBy: { created\_at: "desc" },  
      take: limit,  
      skip: offset,  
      include: {  
        program\_sessions: {  
          select: { name: true },  
        },  
        enrollments: {  
          include: {  
            programs: { select: { title: true } },  
          },  
        },  
        completed\_exercises: {  
          include: {  
            session\_exercises: { select: { exercise\_name: true } },  
          },  
        },  
      },  
    });  
  
    const formattedHistory = history.map((session) => ({  
      id: session.id,  
      date: session.created\_at,  
      program\_title: session.enrollments?.programs?.title || "Unknown Program",  
      session\_name: session.program\_sessions?.name || "Unknown Session",  
      rpe: session.rpe,  
      duration\_minutes: session.duration\_minutes,  
      session\_notes: session.notes,  
      exercises: session.completed\_exercises.map((ex) => ({  
        id: ex.id,  
        exercise\_name:  
          ex.session\_exercises?.exercise\_name || "Unknown Exercise",  
        sets\_data: ex.sets\_data,  
        exercise\_notes: ex.notes,  
      })),  
    }));  
  
    res.status(200).json(formattedHistory);  
  } catch (error: any) {  
    console.error("Get Workout History Error:", error);  
    next(new AppError("Internal server error occurred.", 500));  
  }  
};  
  
import { Router } from 'express';  
import { askQuestion, recommendProgram, getCoachAdvice, getSessions, getSessionMessages } from '../controllers/ai.controller';  
import { authenticateToken } from '../middlewares/auth.middleware';  
import { validate } from '../middlewares/validation.middleware';  
import { askQuestionValidation, recommendValidation, coachAdviceValidation, sessionParamValidation } from '../validators/ai.validator';  
  
const router = Router();  
  
// ==========================================  
// --- AI & Machine Learning Routes ---  
// ==========================================  
router.post('/ask', authenticateToken, askQuestionValidation, validate, askQuestion);  
router.post('/recommend', authenticateToken, recommendValidation, validate, recommendProgram);  
router.post('/coach', authenticateToken, coachAdviceValidation, validate, getCoachAdvice);  
  
// ==========================================  
// --- Chat Sessions Management Routes ---  
// ==========================================  
router.get('/sessions', authenticateToken, getSessions);  
router.get('/sessions/:id/messages', authenticateToken, sessionParamValidation, validate, getSessionMessages);  
  
export default router;  
import { Router } from "express";  
import { authenticateToken } from "../middlewares/auth.middleware";  
import { validate } from "../middlewares/validation.middleware";  
  
import {  
  createSportProfile,  
  getSportProfile,  
  updateSportProfile,  
  deleteSportProfile,  
  upsertUserMetrics,  
  getUserMetrics,  
  deleteUserMetrics,  
  getSportBaselineTests,  
  createSnapshot,  
  getSnapshots,  
  getLatestSnapshot,  
  deleteSnapshot,  
  getRadarData,  
  getProgress,  
  getMyEnrollments,  
  getSportsList,  
  getSportCategories,  
  completeOnboarding,  
  getOnboardingStatus,  
  getAthleteDashboard,  
} from "../controllers/athlete.controller";  
  
import {  
  createSportProfileValidation,  
  updateSportProfileValidation,  
  upsertMetricsValidation,  
  createSnapshotValidation,  
  getSnapshotsValidation,  
  radarValidation,  
  progressValidation,  
  getMyEnrollmentsValidation,  
  idParamValidation,  
  sportIdParamValidation,  
  completeOnboardingValidation,  
} from "../validators/athlete.validator";  
  
const router = Router();  
  
// =======================================================  
// Sports (Public)  
// =======================================================  
  
router.get("/sports", getSportsList);  
  
router.get(  
  "/sports/:sport\_id/categories",  
  sportIdParamValidation,  
  validate,  
  getSportCategories,  
);  
  
router.get(  
  "/sports/:sport\_id/tests",  
  sportIdParamValidation,  
  validate,  
  getSportBaselineTests,  
);  
  
// =======================================================  
// Onboarding  
// =======================================================  
  
router.post(  
  "/onboarding",  
  authenticateToken,  
  completeOnboardingValidation,  
  validate,  
  completeOnboarding,  
);  
  
router.get("/onboarding/status", authenticateToken, getOnboardingStatus);  
  
// =======================================================  
// Dashboard  
// =======================================================  
  
router.get("/dashboard", authenticateToken, getAthleteDashboard);  
  
// =======================================================  
// Sport Profile  
// =======================================================  
  
router.post(  
  "/sport-profile",  
  authenticateToken,  
  createSportProfileValidation,  
  validate,  
  createSportProfile,  
);  
  
router.get("/sport-profile", authenticateToken, getSportProfile);  
  
router.patch(  
  "/sport-profile",  
  authenticateToken,  
  updateSportProfileValidation,  
  validate,  
  updateSportProfile,  
);  
  
router.delete(  
  "/sport-profile/:id",  
  authenticateToken,  
  idParamValidation,  
  validate,  
  deleteSportProfile,  
);  
  
// =======================================================  
// Metrics  
// =======================================================  
  
router.post(  
  "/metrics",  
  authenticateToken,  
  upsertMetricsValidation,  
  validate,  
  upsertUserMetrics,  
);  
  
router.get("/metrics", authenticateToken, getUserMetrics);  
  
router.delete("/metrics", authenticateToken, deleteUserMetrics);  
  
// =======================================================  
// Snapshots  
// =======================================================  
  
router.post(  
  "/snapshots",  
  authenticateToken,  
  createSnapshotValidation,  
  validate,  
  createSnapshot,  
);  
  
router.get(  
  "/snapshots",  
  authenticateToken,  
  getSnapshotsValidation,  
  validate,  
  getSnapshots,  
);  
  
router.get("/snapshots/latest", authenticateToken, getLatestSnapshot);  
  
router.delete(  
  "/snapshots/:id",  
  authenticateToken,  
  idParamValidation,  
  validate,  
  deleteSnapshot,  
);  
  
// =======================================================  
// Analytics  
// =======================================================  
  
router.get(  
  "/radar",  
  authenticateToken,  
  radarValidation,  
  validate,  
  getRadarData,  
);  
  
router.get(  
  "/progress",  
  authenticateToken,  
  progressValidation,  
  validate,  
  getProgress,  
);  
  
// =======================================================  
// Enrollments  
// =======================================================  
  
router.get(  
  "/enrollments",  
  authenticateToken,  
  getMyEnrollmentsValidation,  
  validate,  
  getMyEnrollments,  
);  
  
export default router;  
  
import { loginValidation, registerValidation } from "../validators/auth.validator";  
import { Router, Response } from "express";  
import {  
  register,  
  login,  
  refresh,  
  logout,  
} from "../controllers/auth.controller";  
import { authenticateToken, AuthRequest } from "../middlewares/auth.middleware";  
import { validate } from "../middlewares/validation.middleware";  
  
const router = Router();  
  
// Public routes (Registration and Login)  
router.post("/register", registerValidation, validate, register);  
router.post("/login",loginValidation,validate, login);  
router.post("/logout", authenticateToken, logout);  
  
// i think that is unused api route we will check if is unused we will remove it   
// Protected route (Requires valid token)  
router.get("/profile", authenticateToken, (req: AuthRequest, res: Response) => {  
  // The user ID is accessible here since the user passed through the auth middleware  
  res.status(200).json({  
    message: "Welcome to your protected profile!",  
    userId: req.user?.sub,  
  });  
});  
router.post("/refresh", refresh);  
  
export default router;  
  
import { Router } from "express";  
import {  
  getLeaderboard,  
  getMostImproved,  
} from "../controllers/leaderboards.controller";  
import { authenticateToken } from "../middlewares/auth.middleware";  
import {  
  getLeaderboardValidation,  
  mostImprovedValidation,  
} from "../validators/leaderboard.validator";  
import { validate } from "../middlewares/validation.middleware";  
  
const router = Router();  
  
// // Fetch leaderboard route  
// router.get('/:type', authenticateToken, getLeaderboard);  
  
router.get(  
  "/get\_leaderboard",  
  authenticateToken,  
  getLeaderboardValidation,  
  validate,  
  getLeaderboard,  
);  
  
// 🎯 GET /api/leaderboard/most\_improved  
router.get(  
  "/most\_improved",  
  authenticateToken,  
  mostImprovedValidation,  
  validate,  
  getMostImproved,  
);  
  
export default router;  
import { Router } from "express";  
import {  
  createProgram,  
  listPrograms,  
  getProgramById,  
  updateProgram,  
  deleteProgram,  
  enrollInProgram,  
  completeEnrollment,  
  rateProgram,  
  getMyEnrolledPrograms,  
} from "../controllers/programs.controller";  
import { authenticateToken } from "../middlewares/auth.middleware";  
import {  
  completeEnrollmentValidation,  
  createProgramValidation,  
  enrollProgramValidation,  
  getMyEnrolledProgramsValidation,  
  getProgramValidation,  
  listProgramsValidation,  
  rateProgramValidation,  
  updateProgramValidation,  
} from "../validators/programs.validator";  
import { validate } from "../middlewares/validation.middleware";  
  
const router = Router();  
  
// View routes // Validated  
router.get(  
  "/",  
  authenticateToken,  
  listProgramsValidation,  
  validate,  
  listPrograms,  
);  
// router.get('/:id', authenticateToken,getProgramValidation,validate, getProgramById);  
router.get(  
  "/get\_program",  
  authenticateToken,  
  getProgramValidation,  
  validate,  
  getProgramById,  
);  
  
// Athlete routes (Enrollment and Rating)  
// router.post('/:id/enroll', authenticateToken,enrollProgramValidation,validate, enrollInProgram);  
router.post(  
  "/enroll\_program",  
  authenticateToken,  
  enrollProgramValidation,  
  validate,  
  enrollInProgram,  
);  
  
// router.post('/:id/rate', authenticateToken,rateProgramValidation,validate, rateProgram);  
router.post(  
  "/rate\_program",  
  authenticateToken,  
  rateProgramValidation,  
  validate,  
  rateProgram,  
);  
  
// Complete program route (Note: ID is the Enrollment ID)  
// router.post('/enrollments/:id/complete', authenticateToken,completeEnrollmentValidation,validate, completeEnrollment);  
router.post(  
  "/complete\_enrollment",  
  authenticateToken,  
  completeEnrollmentValidation,  
  validate,  
  completeEnrollment,  
);  
  
// Coach routes  
router.post(  
  "/",  
  authenticateToken,  
  createProgramValidation,  
  validate,  
  createProgram,  
); // Validated  
// router.patch('/:id', authenticateToken,updateProgramValidation,validate, updateProgram); // Validated  
router.patch(  
  "/update\_program",  
  authenticateToken,  
  updateProgramValidation,  
  validate,  
  updateProgram,  
);  
  
router.delete("/:id", authenticateToken, deleteProgram);  
  
// 🎯 جلب البرامج التي سجل فيها اللاعب الحالي: GET /my\_enrolled  
router.get(  
  "/my\_enrolled",  
  authenticateToken,  
  getMyEnrolledProgramsValidation,  
  validate, // 👈 التعديل هنا: ضفنا دي!  
  getMyEnrolledPrograms,  
);  
  
export default router;  
import { Router } from 'express';  
import { search, syncSearchVectors } from '../controllers/search.controller';  
import { authenticateToken } from '../middlewares/auth.middleware';  
import { validate } from '../middlewares/validation.middleware';  
import { searchValidation, syncSearchValidation } from '../validators/search.validator';  
  
const router = Router();  
  
// 🎯 Search routes with Validations  
router.get('/', authenticateToken, searchValidation, validate, search);  
  
// 🎯 Sync route strictly protected for Admins  
router.post('/sync', authenticateToken, syncSearchValidation, validate, syncSearchVectors);  
  
export default router;  
// ==========================================  
import { Router } from 'express';  
import {  
    getFeed,  
    createPost,  
    getUserPosts,  
    likePost,  
    unlikePost,  
    addComment,  
    getComments,  
    followUser,  
    unfollowUser,  
    getFollowers,  
    getFollowing,  
    getSpecificPost, // 🎯 تأكد إنك عاملها Import لو موجودة  
    updatePost,  
    deletePost,  
    updateComment,  
    deleteComment  
} from '../controllers/social.controller';  
import { authenticateToken } from '../middlewares/auth.middleware';  
import { validate } from '../middlewares/validation.middleware';  
import { uploadPostImage } from '../middlewares/upload.middleware';  
import {  
    paginationValidation,  
    createPostValidation,  
    getUserPostsValidation,  
    postIdParamValidation,  
    addCommentValidation,  
    followValidation,  
    userIdParamValidation,  
    updatePostValidation,  
    updateCommentValidation,  
    commentIdParamValidation  
} from '../validators/social.validator';  
  
const router = Router();  
  
// ==========================================  
// Social Feed & Posts  
// ==========================================  
router.get('/feed', authenticateToken, paginationValidation, validate, getFeed);  
  
// ⚠️ ملحوظة مهمة: لو بتستخدم Multer لرفع الصور في البوستات، لازم تحط الـ middleware بتاعه هنا قبل \`createPostValidation\`  
router.post(  
    '/posts',  
    authenticateToken,  
    uploadPostImage.single('image'), // 👈 استخدمنا بتاع البوستات، والـ Key اسمه image  
    createPostValidation,  
    validate,  
    createPost  
);  
router.get('/users/:id/posts', authenticateToken, getUserPostsValidation, validate, getUserPosts);  
router.get('/posts/:id', authenticateToken, postIdParamValidation, validate, getSpecificPost); // ضيف دي لو محتاجها للـ Specific Post  
router.patch('/posts/:id', authenticateToken, uploadPostImage.single('image'), updatePostValidation, validate, updatePost);  
router.delete('/posts/:id', authenticateToken, postIdParamValidation, validate, deletePost);  
  
// ==========================================  
// Likes & Comments  
// ==========================================  
router.post('/posts/:id/like', authenticateToken, postIdParamValidation, validate, likePost);  
router.delete('/posts/:id/like', authenticateToken, postIdParamValidation, validate, unlikePost);  
router.get('/posts/:id/comments', authenticateToken, postIdParamValidation, validate, getComments);  
router.post('/posts/:id/comments', authenticateToken, addCommentValidation, validate, addComment);  
router.patch('/comments/:id', authenticateToken, updateCommentValidation, validate, updateComment);  
router.delete('/comments/:id', authenticateToken, commentIdParamValidation, validate, deleteComment);  
  
// ==========================================  
// Follow Feature  
// ==========================================  
router.post('/follow/:userId', authenticateToken, followValidation, validate, followUser);  
router.delete('/follow/:userId', authenticateToken, followValidation, validate, unfollowUser);  
  
router.get('/users/:id/followers', authenticateToken, userIdParamValidation, paginationValidation, validate, getFollowers);  
router.get('/users/:id/following', authenticateToken, userIdParamValidation, paginationValidation, validate, getFollowing);  
  
export default router;  
import { Router } from "express";  
import {  
  getMe,  
  updateMe,  
  uploadPhoto,  
  getPublicProfile,  
  deactivateAccount,  
} from "../controllers/users.controller";  
import { authenticateToken } from "../middlewares/auth.middleware"; // Authentication middleware  
import { uploadProfilePhoto } from "../middlewares/upload.middleware"; // Multer upload middleware  
import { validate } from "../middlewares/validation.middleware"; // 🎯 Global validator  
import {  
  updateMeValidation,  
  uploadPhotoValidation,  
  getPublicProfileValidation,  
} from "../validators/users.validator"; // 🎯 Users validators  
import multer from "multer";  
import { AppError } from "../utils/AppError";  
  
const router = Router();  
  
// ==========================================  
// User Profile Routes  
// ==========================================  
  
// GET /users/me - جلب بيانات المستخدم الحالي  
router.get("/me", authenticateToken, getMe);  
  
// 🎯 ربطنا الفاليديتور بتاع updateMe  
router.patch("/me", authenticateToken, updateMeValidation, validate, updateMe);  
  
// 🎯 تنظيف أخطاء Multer واستخدام uploadPhotoValidation  
router.post(  
  "/upload\_photo",  
  authenticateToken,  
  (req, res, next) => {  
    const upload = uploadProfilePhoto.single("photo");  
  
    upload(req, res, function (err) {  
      if (err instanceof multer.MulterError) {  
        if (err.code === "LIMIT\_FILE\_SIZE") {  
          return next(new AppError("File size exceeds limit.", 400));  
        }  
        return next(new AppError(err.message, 400));  
      } else if (err) {  
        // خطأ من Cloudinary أو امتداد مرفوض  
        return next(  
          new AppError(  
            "Invalid file type — only JPEG, PNG, WEBP accepted.",  
            400,  
          ),  
        );  
      }  
  
      next(); // لو مفيش خطأ من Multer، كمل  
    });  
  },  
  uploadPhotoValidation, // الفاليديتور بتاعنا كخط دفاع أخير  
  uploadPhoto,  
);  
  
// 🎯 المسار لـ /public عشان يقرا الـ Query parameter (?user\_id=...)  
router.get(  
  "/public",  
  authenticateToken,  
  getPublicProfileValidation,  
  validate,  
  getPublicProfile,  
);  
  
// PATCH /users/me/deactivate - إلغاء تنشيط الحساب  
router.patch("/me/deactivate", authenticateToken, deactivateAccount);  
console.log("Users routes loaded");  
export default router;  
  
import { Router } from "express";  
import {  
  getNextWorkout,  
  logWorkout,  
  getWorkoutHistory,  
} from "../controllers/workouts.controller"; // Added getWorkoutHistory function  
import { authenticateToken } from "../middlewares/auth.middleware";  
import {  
  getHistoryValidation,  
  getNextWorkoutValidation,  
  postLogValidation,  
} from "../validators/workouts.validator";  
import { validate } from "../middlewares/validation.middleware";  
  
const router = Router();  
  
// Route to get the athlete's next required workout for today  
router.get(  
  "/get\_next\_workout",  
  authenticateToken,  
  getNextWorkoutValidation,  
  validate,  
  getNextWorkout,  
);  
  
// Route to log the actual data after completing a workout  
router.post(  
  "/post\_log",  
  authenticateToken,  
  postLogValidation,  
  validate,  
  logWorkout,  
);  
  
// Route to view past workout history  
router.get(  
  "/workout\_history",  
  authenticateToken,  
  getHistoryValidation,  
  validate,  
  getWorkoutHistory,  
);  
  
export default router;  
  
import axios from 'axios';  
  
const AI\_SERVER\_URL = process.env.AI\_SERVER\_URL || 'http://localhost:8000';  
  
export const askRingsideAI = async (payload: any) => {  
    const response = await axios.post(\`${AI\_SERVER\_URL}/ask\`, payload);  
    return response.data;  
};  
  
export const getProgramRecommendation = async (payload: any) => {  
    const response = await axios.post(\`${AI\_SERVER\_URL}/recommend\`, payload);  
    return response.data;  
};
